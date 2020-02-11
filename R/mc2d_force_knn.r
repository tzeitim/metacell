#' Metacell layout using force directed projection of a low degree mc graph
#'
#' @param mc2d_id 2d object to add
#' @param mc_id meta cell id to work with
#' @param graph_id graph_id of the similarity graph on cells from the metacell
#' @param symetrix should the mc confusion matrix be symmetrized before computing layout?
#' @param ignore_mismatch
#'
#' @export
mcell_mc2d_force_knn = function(mc2d_id, mc_id, graph_id, ignore_mismatch=F, symmetrize=F, ignore_edges = NULL, use_umap_on_mc_egc=F, gset_for_umap=NULL, uconf=NULL, umap_exclude_genes=NULL)
{
	mc = scdb_mc(mc_id)
	if (is.null(mc)) {
		stop(sprintf("mc %s not found"), mc_id)
	}
	mgraph = mc2d_comp_mgraph(mc_id, graph_id, ignore_mismatch=ignore_mismatch, symmetrize=symmetrize)
	if(!is.null(ignore_edges)) {
		all_e = paste(mgraph$mc1, mgraph$mc2, sep="-")
		ig_e = paste(ignore_edges$mc1, ignore_edges$mc2, sep="-")
		ig_re = paste(ignore_edges$mc2, ignore_edges$mc1, sep="-")
		f = all_e %in% c(ig_e,ig_re)
		mgraph= mgraph[!f,]
		message("igoring ", sum(f), " edges")
	}
	if(use_umap_on_mc_egc) {
		if(is.null(gset_for_umap)) {
			stop("Specifiy a gene set for layout using umap on mc egc")
		}
		if(is.null(uconf)) {
			uconf = umap.defaults
			uconf$n_neighbors=6
			uconf$min_dist=0.9
			uconf$bandwidth=1.3
		}
		gset = scdb_gset(gset_for_umap)
		genes = names(gset@gene_set)
		if(!is.null(umap_exclude_genes)) {
			genes = setdiff(genes, umap_exclude_genes)
			message("remove exclude, total now ", length(genes))
		}
		message("map with gset ", gset_for_umap, " on ", length(genes), " genes")
		mc_xy = mc2d_comp_graph_coord_umap(mc, genes, uconf)
	} else {
		mc_xy = mc2d_comp_graph_coord(mgraph, N=ncol(mc@mc_fp))
	}
	xy = mc2d_comp_cell_coord(mc_id, graph_id, mgraph, mc_xy, symmetrize=symmetrize)
	scdb_add_mc2d(mc2d_id, tgMC2D(mc_id, mc_xy$mc_x, mc_xy$mc_y, xy$x, xy$y, mgraph))
}

#' Compute cells 2d coordinates based on the mc graph when the mc coordinates are supplied externally 
#'
#' @param mc2d_id 2d object to add
#' @param mc_id meta cell id to work with
#' @param graph_id graph_id of the similarity graph on cells from the metacell
#' @param mc_xy pre-defined metacells coordinates (so only coordinates of cells will be computed). Data frame with 2 columns named mc_x and mc_y (x and y coodinates, respectively). 
#' @param ignore_mismatch
#'
#' @export
mcell_mc2d_force_knn_on_cells = function(mc2d_id, mc_id, graph_id, mc_xy, ignore_mismatch=F)
{
	mgraph = mc2d_comp_mgraph(mc_id, graph_id, ignore_mismatch=ignore_mismatch)
	xy = mc2d_comp_cell_coord(mc_id, graph_id, mgraph, mc_xy)
	scdb_add_mc2d(mc2d_id, tgMC2D(mc_id, mc_xy$mc_x, mc_xy$mc_y, xy$x, xy$y, mgraph))
}

#' @export
mc2d_comp_mgraph = function(mc_id, graph_id, ignore_mismatch=F, symmetrize=F)
{
	mc2d_K = get_param("mcell_mc2d_K")
	mc2d_T_edge = get_param("mcell_mc2d_T_edge")
	mc2d_max_confu_deg = get_param("mcell_mc2d_max_confu_deg")
	mc2d_edge_asym = get_param("mcell_mc2d_edge_asym")
	mc2d_k_expand_inout_factor = get_param("mcell_mc2d_expand_inout_factor")
	mc2d_max_fpcor_indeg = get_param("mcell_mc2d_max_fpcor_indeg")
	mc2d_max_fpcor_outdeg = get_param("mcell_mc2d_max_fpcor_outdeg")

	if(is.null(mc2d_max_confu_deg) & is.null(mc2d_max_fpcor_outdeg)) {
		stop("MC-ERR: Either max_confu_deg or max_fpcor_deg must be defined - currently both are null")
	}

	graph = scdb_cgraph(graph_id)
	if(is.null(graph)) {
		stop("MC-ERR: cell graph id ", graph_id, " is missing when mc 2d projection")
	}
	mc = scdb_mc(mc_id)
	if(is.null(mc)) {
		stop("MC-ERR: mc id ", mc_id, " is missing when running add_mc_from_graph")
	}
	restrict_in_degree = T

	if(!is.null(mc2d_max_confu_deg)) {

		message("comp mc graph using the graph ", graph_id, " and K ", mc2d_K)
		confu = mcell_mc_confusion_mat(mc_id, graph_id, mc2d_K, 
													ignore_mismatch=ignore_mismatch)
		if(symmetrize) {
			confu =confu + t(confu)
		}
# k_expand_inout_factor=k_expand_inout_factor

		csize = as.matrix(table(mc@mc))
		csize = pmax(csize, 20)
		csize2 = csize %*% t(csize)
		csize2 = csize2 / median(csize)**2
		confu = confu / csize2

		confu_p_from = confu/rowSums(confu)
		confu_p_to = t(confu)/colSums(confu)

		if(!is.null(mc2d_max_confu_deg)) {
			rank_fr = t(apply(confu_p_from, 1, rank))
			rank_to = t(apply(confu_p_to, 1, rank))
			rank2 = rank_fr * rank_to
			diag(rank2) = 1e+6
			amgraph = apply(rank2, 1, function(x) {  rank(-x) <= (1+mc2d_max_confu_deg) })
			mgraph = amgraph * ((confu_p_from + confu_p_to) > mc2d_T_edge)
			if(restrict_in_degree) {
				amgraph2 = t(apply(rank2, 2, function(x) {  rank(-x) <= (1+mc2d_max_confu_deg) }))
				mgraph = mgraph * amgraph2
			}

			if(mc2d_edge_asym) {
				mgraph = amgraph * (confu_p_from>mc2d_T_edge)
				mgraph = amgraph * (t(confu_p_to)>mc2d_T_edge)
			}
			mgraph = mgraph>0 | t(mgraph>0)
		} else {
			mgraph = (confu_p_from + confu_p_to) > mc2d_T_edge
		}
	}

	if(!is.null(mc2d_max_fpcor_outdeg)) {
		f = apply(abs(log2(mc@mc_fp)),1,max)>0.5
		fp_cor = tgs_cor(log2(mc@mc_fp[f,]))
		fp_rnk = t(apply(-fp_cor,1,function(x) rank(x)<=(mc2d_max_fpcor_outdeg+1)))
		fp_rnk_in = apply(-fp_cor,1,function(x) rank(x)<=(1+mc2d_max_fpcor_indeg))
		if(!is.null(mc2d_max_confu_deg)) {
				  mgraph = mgraph * fp_rnk * fp_rnk_in
		} else {
				  mgraph = fp_rnk * fp_rnk_in
		}
	}

	N = nrow(mgraph)
	e = which(mgraph>0)
	n1 = ceiling((e)/N)
	n2 = 1+((e-1) %% N)
	return(data.frame(mc1 = n1, mc2 = n2))
}

#' @export
mc2d_comp_graph_coord_umap = function(mc, genes, uconf)
{
	legc = log2(mc@e_gc[genes,] + 1e-5)
	um = umap(t(legc), uconf)
	return(list(mc_x=um$layout[,1], mc_y=um$layout[,2]))
}

#' @importClassesFrom graph graphNEL
#' @importFrom graph plot addEdge addNode nodeRenderInfo
#' @importFrom Rgraphviz layoutGraph
#' @export
mc2d_comp_graph_coord = function(mc_graph, N)
{
	n1 = mc_graph$mc1
	n2 = mc_graph$mc2
	rEG <- new("graphNEL", nodes=as.character(1:N), edgemode="undirected")

	rEG = addEdge(as.character(n1[n1!=n2]), as.character(n2[n1!=n2]), rEG, rep(1, length(n1[n1!=n2])))

	g = layoutGraph(rEG, layoutType="neato")
	x_cl = nodeRenderInfo(g)$nodeX
	y_cl = nodeRenderInfo(g)$nodeY
	names(x_cl) = 1:N
	names(y_cl) = 1:N
	return(list(g=g, mc_x=x_cl, mc_y=y_cl))
}

#' @export
mc2d_comp_cell_coord = function(mc_id, graph_id, mgraph, cl_xy, skip_missing=F, symmetrize=F)
{
	mc2d_proj_blur = get_param("mcell_mc2d_proj_blur")
	mc2d_K_cellproj = get_param("mcell_mc2d_K_cellproj")


	mc = scdb_mc(mc_id)
	graph = scdb_cgraph(graph_id)

	x_cl = cl_xy$mc_x
	y_cl = cl_xy$mc_y

	N_mc = length(x_cl)
	N_c = length(mc@mc)+length(mc@outliers)
	if(N_mc != length(mc@colors)) {
		stop("MC-ERR: Length mismatch in number of projected MC and overal mc")
	}

	blurx = mc2d_proj_blur*(max(x_cl) - min(x_cl))
	blury = mc2d_proj_blur*(max(y_cl) - min(y_cl))

#defining all pairs of MCs that are connected on the mc graph sekelton as active
	is_active = rep(FALSE, N_mc*N_mc)
	is_active[(mgraph$mc1-1) * N_mc + mgraph$mc2] = TRUE
	if(symmetrize) {
		message("project on symmetrized graph")
		is_active[(mgraph$mc2-1) * N_mc + mgraph$mc1] = TRUE
	}
#including the diagnoal
	is_active[((1:N_mc)-1) * N_mc + 1:N_mc] = TRUE

	mc_key1 = mc@mc[levels(graph@edges$mc1)]
	mc_key2 = mc@mc[levels(graph@edges$mc2)]
	mc1 = mc_key1[graph@edges$mc1]
	mc2 = mc_key2[graph@edges$mc2]
	e_wgts = graph@edges$w
	if(symmetrize) {
		amc1 = c(mc1, mc2)
		amc2 = c(mc2, mc1)
		mc1 = amc1
		mc2 = amc2
		e_wgts = c(e_wgts, e_wgts)
	}

	f_in_mc = !is.na(mc1) & !is.na(mc2) #missing mc's, for example orphans
	f_active = is_active[(mc1-1)*N_mc + mc2]
	f = !is.na(f_active) & f_in_mc & f_active

	deg = nrow(graph@edges[f,])/length(graph@nodes)
	if(symmetrize) {
		deg = 2*deg
	}
	T_w = 1-(mc2d_K_cellproj+1)/deg
	f = f & e_wgts > T_w

	to_x = x_cl[mc2]
	to_y = y_cl[mc2]
	if(symmetrize) {
		edges_mcs = c(as.character(graph@edges$mc1), as.character(graph@edges$mc2))[f]
		c_x = tapply(to_x[f], edges_mcs, mean)
		c_y = tapply(to_y[f], edges_mcs, mean)
		c_x = c_x[names(mc@mc)]
		c_y = c_y[names(mc@mc)]
		names(c_x) = names(mc@mc)
		names(c_y) = names(mc@mc)
	} else {
		c_x = tapply(to_x[f], as.character(graph@edges$mc1[f]), mean)
		c_y = tapply(to_y[f], as.character(graph@edges$mc1[f]), mean)
	}

	base_x = min(c_x)
	base_y = min(c_y)
	max_x = max(c_x)
	base_x = base_x - (max_x-base_x)*0.1

	miss = setdiff(names(mc@mc), names(c_x))
	if(length(miss) > 0) {
		message("Missing coordinates in some cells that are not ourliers or ignored - check this out! (total ", length(miss), " cells are missing, maybe you used the wrong graph object?", " first nodes ", head(miss,10))
#		stop("existing")
	}
	x = c_x[names(mc@mc)]
	y = c_y[names(mc@mc)]
	x = x + rnorm(mean=0, sd=blurx, n=length(x))
	y = y + rnorm(mean=0, sd=blury, n=length(y))

	return(list(x=x, y=y))
}