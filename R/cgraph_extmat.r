#' Build a cell graph using blanacing of an extrenal distance matrix
#'
#' @param mat_id matrix object id
#' @param d_mat distance matrix, col and row names should be a super set of the non ignored cells for the matrix in mat_id
#' @param graph_id  new graph id to create
#' @param K the guideline Knn parameter. The balanced will be constructed aiming at K edges per cell
#' @param balance should balancing be performed (Default False)
#' @param k_expand determine how much shoudl the K be expanded intially in order to find enough balanced neighbors.
#'
#' @export

mcell_add_cgraph_from_distmat= function(d_mat, graph_id, K, balance=F, k_expand=10)
{
	k_beta = get_param("scm_balance_graph_k_beta")

	d_mat = as.matrix(d_mat)

	if(balance) {
		x_knn = tgs_knn(max(d_mat)-d_mat, K*k_expand)
		message("will build balanced knn graph on ", ncol(d_mat), " cells, this can be a bit heavy for >20,000 cells")
		gr = tgs_graph(x_knn, K, k_expand, k_beta)
	} else {
		x_knn = tgs_knn(max(d_mat)-d_mat, K)
		gr = x_knn[,c("col1", "col2")]
		gr$w = 1-(x_knn$rank-1)/K
	}
	colnames(gr) = c("mc1","mc2","w")

	scdb_add_cgraph(graph_id, tgCellGraph(gr, colnames(d_mat)))
}
