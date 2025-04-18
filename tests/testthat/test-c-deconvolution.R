library(omnideconv)

chk <- Sys.getenv("_R_CHECK_LIMIT_CORES_", "")


# Somehow, ncores != 1 breaks the coverage tests!
###################################################
# if (nzchar(chk) && chk == "TRUE") {
#   # use 2 cores in CRAN/Travis/AppVeyor
#   ncores <- 2L
# } else {
#   # use all cores in devtools::test()
#   ncores <- parallel::detectCores()
# }



bulk_small <- system.file("small_test_data", "bulk_small.csv",
  package = "omnideconv", mustWork = TRUE
) %>%
  utils::read.csv(., row.names = 1) %>%
  as.matrix(.)

bulk_small_one_sample <- bulk_small[, 1, drop = FALSE]


sc_object_small <- system.file("small_test_data", "sc_object_small.csv",
  package = "omnideconv", mustWork = TRUE
) %>%
  utils::read.csv(., row.names = 1) %>%
  as.matrix(.)

cell_annotations_small <- system.file("small_test_data", "cell_annotations_small.txt",
  package = "omnideconv", mustWork = TRUE
) %>%
  readr::read_lines(.)

batch_ids_small <- system.file("small_test_data", "batch_ids_small.txt",
  package = "omnideconv", mustWork = TRUE
) %>%
  readr::read_lines(.)

marker_genes <- system.file("small_test_data", "marker_genes_small.txt",
  package = "omnideconv", mustWork = TRUE
) %>%
  readr::read_lines(.)


# bulk_small <- as.matrix(utils::read.csv("small_test_data", "bulk_small.csv", row.names = 1))

# sc_object_small <- as.matrix(utils::read.csv("small_test_data", "sc_object_small.csv", row.names = 1))
# cell_annotations_small <- readr::read_lines("small_test_data", "cell_annotations_small.txt")
# batch_ids_small <- readr::read_lines("small_test_data", "batch_ids_small.txt")


test_that("Bisque deconvolution works", {
  bisque_model <- system.file("test_models/bisque_model_small.csv",
    package = "omnideconv", mustWork = TRUE
  ) %>%
    read.csv(.,
      row.names = 1,
      check.names = FALSE
    ) %>%
    as.matrix(.)
  deconvolution <- t(.bisque_patched_deconvolution(
    bulk_small, bisque_model,
    sc_object_small, cell_annotations_small, batch_ids_small
  )$bulk.props)
  expect_equal(
    info = "rows of deconvolution equal to columns of signature (same celltypes in same order)",
    object = sort(colnames(deconvolution)), expected = sort(colnames(bisque_model))
  )
  expect_equal(
    info = "deconvolution contains same samples as in bulk (not same order)",
    object = sort(rownames(deconvolution)), expected = sort(colnames(bulk_small))
  )

  check_result <- system.file("test_results", "bisque_result_small.csv",
    package = "omnideconv", mustWork = TRUE
  ) %>%
    read.csv(.,
      row.names = 1,
      check.names = FALSE
    ) %>%
    as.matrix(.)
  expect_equal(
    info = "deconvolution result is correct", object = deconvolution,
    expected = check_result, tolerance = 1e-1
  )
  expect_error(
    info = "bisque is not appliable with just one bulk sample",
    object = deconvolute(bulk_small_one_sample, bisque_model,
      method = "bisque", sc_object_small,
      cell_annotations_small, batch_ids_small
    )
  )

  deconvolution <- deconvolute(bulk_small, NULL,
    method = "bisque", sc_object_small, cell_annotations_small,
    batch_ids_small
  )
  expect_equal(
    info = "deconvolution result is correct", object = deconvolution,
    expected = check_result, tolerance = 1e-1
  )
})

test_that("MOMF deconvolution works", {
  momf_model <- system.file("test_models/momf_model_small.csv",
    package = "omnideconv", mustWork = TRUE
  ) %>%
    read.csv(.,
      row.names = 1,
      check.names = FALSE
    ) %>%
    as.matrix(.)
  deconvolution <- deconvolute(bulk_small, momf_model, method = "momf", sc_object_small)
  expect_equal(
    info = "columns of deconvolution equal to columns of signature (same celltypes in same order)",
    object = sort(colnames(deconvolution)), expected = sort(colnames(momf_model))
  )
  expect_equal(
    info = "deconvolution contains same samples as in bulk (not same order)",
    object = sort(rownames(deconvolution)), expected = sort(colnames(bulk_small))
  )
  check_result <- system.file("test_results", "momf_result_small.csv",
    package = "omnideconv", mustWork = TRUE
  ) %>%
    read.csv(.,
      row.names = 1,
      check.names = FALSE
    ) %>%
    as.matrix(.)
  expect_equal(
    info = "deconvolution result is correct",
    object = deconvolution[, sort(colnames(deconvolution))],
    expected = check_result[, sort(colnames(check_result))],
    tolerance = 1e-3
  )
  expect_equal(
    info = "deconvolution result with one bulk sample throws no error",
    object = nrow(deconvolute(bulk_small_one_sample, momf_model,
      method = "momf", sc_object_small
    )),
    expected = 1
  )
})

test_that("DWLS deconvolution works", {
  dwls_model <- system.file("test_models/dwls_model_small.csv",
    package = "omnideconv", mustWork = TRUE
  ) %>%
    read.csv(.,
      row.names = 1,
      check.names = FALSE
    ) %>%
    as.matrix(.)
  deconvolution_dwls <- deconvolute(bulk_small, dwls_model,
    method = "dwls", dwls_submethod = "DampenedWLS"
  )
  deconvolution_ols <- deconvolute(bulk_small, dwls_model,
    method = "dwls", dwls_submethod = "OLS"
  )
  deconvolution_svr <- deconvolute(bulk_small, dwls_model,
    method = "dwls", dwls_submethod = "SVR"
  )

  deconvolution_dwls_noSignature <- deconvolute(bulk_small,
    model = NULL,
    method = "dwls",
    sc_object_small, cell_annotations_small,
    dwls_submethod = "DampenedWLS"
  )

  expect_equal(
    info = "rows of deconv for dwls equal to columns of signature (same celltypes, not same order)",
    object = sort(colnames(deconvolution_dwls)), expected = sort(colnames(dwls_model))
  )
  expect_equal(
    info = "deconvolution of dwls contains same samples as in bulk (not same order)",
    object = sort(rownames(deconvolution_dwls)), expected = sort(colnames(bulk_small))
  )
  expect_equal(
    info = "rows of deconv for ols equal to columns of signature (same celltypes, not same order)",
    object = sort(colnames(deconvolution_ols)), expected = sort(colnames(dwls_model))
  )
  expect_equal(
    info = "deconvolution of ols contains same samples as in bulk (not same order)",
    object = sort(rownames(deconvolution_ols)), expected = sort(colnames(bulk_small))
  )
  expect_equal(
    info = "rows of deconv for svr equal to columns of signature (same celltypes, not same order)",
    object = sort(colnames(deconvolution_svr)), expected = sort(colnames(dwls_model))
  )
  expect_equal(
    info = "deconvolution of svr contains same samples as in bulk (not same order)",
    object = sort(rownames(deconvolution_svr)), expected = sort(colnames(bulk_small))
  )

  expect_equal(
    info = "one-step deconvolution and two-step deconvolution produce the same result",
    object = deconvolution_dwls_noSignature, expected = deconvolution_dwls,
    tolerance = 1e-3
  )

  check_result_dwls <- system.file("test_results", "dwls_dwls_result_small.csv",
    package = "omnideconv", mustWork = TRUE
  ) %>%
    read.csv(.,
      row.names = 1,
      check.names = FALSE
    ) %>%
    as.matrix(.)
  check_result_ols <- system.file("test_results", "dwls_ols_result_small.csv",
    package = "omnideconv", mustWork = TRUE
  ) %>%
    read.csv(.,
      row.names = 1,
      check.names = FALSE
    ) %>%
    as.matrix(.)
  check_result_svr <- system.file("test_results", "dwls_svr_result_small.csv",
    package = "omnideconv", mustWork = TRUE
  ) %>%
    read.csv(.,
      row.names = 1,
      check.names = FALSE
    ) %>%
    as.matrix(.)
  expect_equal(
    info = "deconvolution result for dwls is correct",
    object = deconvolution_dwls[, sort(colnames(deconvolution_dwls))],
    expected = check_result_dwls[, sort(colnames(check_result_dwls))], tolerance = 1e-3
  )
  expect_equal(
    info = "deconvolution result for dwls is correct",
    object = deconvolution_ols[, sort(colnames(deconvolution_ols))],
    expected = check_result_ols[, sort(colnames(check_result_ols))], tolerance = 1e-3
  )
  expect_equal(
    info = "deconvolution result for dwls is correct",
    object = deconvolution_svr[, sort(colnames(deconvolution_svr))],
    expected = check_result_svr[, sort(colnames(check_result_svr))], tolerance = 1e-3
  )

  expect_equal(
    info = "deconvolution result with one bulk sample throws no error",
    object = nrow(deconvolute(bulk_small_one_sample, dwls_model,
      method = "dwls", sc_object_small,
      dwls_submethod = "DampenedWLS"
    )),
    expected = 1
  )

  expect_equal(
    info = "deconvolution result with one bulk sample throws no error",
    object = nrow(deconvolute(bulk_small_one_sample, dwls_model,
      method = "dwls", sc_object_small,
      dwls_submethod = "OLS"
    )),
    expected = 1
  )

  expect_equal(
    info = "deconvolution result with one bulk sample throws no error",
    object = nrow(deconvolute(bulk_small_one_sample, dwls_model,
      method = "dwls", sc_object_small,
      dwls_submethod = "SVR"
    )),
    expected = 1
  )
})

test_that("CIBERSORTx deconvolution works, with and without signature", {
  set_cibersortx_credentials(Sys.getenv("CIBERSORTX_EMAIL"), Sys.getenv("CIBERSORTX_TOKEN"))

  cibersort_model <- system.file("test_models", "cibersortx_model_small.tsv",
    package = "omnideconv", mustWork = TRUE
  ) %>%
    read.csv(.,
      row.names = 1,
      check.names = FALSE, sep = "\t"
    ) %>%
    as.matrix(.)
  # colnames(cibersort_model) <- c("T$ c!ell% CD4", "T cel§l() &CD8", "NK+ c?[]el{}l")

  deconvolution <- deconvolute(bulk_small,
    model = cibersort_model,
    method = "cibersortx", container = "docker"
  )

  deconvolution_extra_info <- deconvolute(bulk_small,
    model = cibersort_model,
    method = "cibersortx", container = "docker",
    display_extra_info = TRUE
  )


  deconvolution <- deconvolution[
    sort(rownames(deconvolution)),
    sort(colnames(deconvolution))
  ]

  deconvolution_noSignature <- deconvolute(bulk_small,
    model = NULL,
    method = "cibersortx",
    sc_object_small, cell_annotations_small
  )
  deconvolution_noSignature <- deconvolution_noSignature[
    sort(rownames(deconvolution_noSignature)),
    sort(colnames(deconvolution_noSignature))
  ]
  expect_equal(
    info = "columns of deconvolution equal to columns of signature (same celltypes in same order)",
    object = sort(colnames(deconvolution)), expected = sort(colnames(cibersort_model))
  )
  expect_equal(
    info = "deconvolution contains same samples as in bulk (not same order)",
    object = sort(rownames(deconvolution)), expected = sort(colnames(bulk_small))
  )
  expect_equal(
    info = "one-step deconvolution and two-step deconvolution produce the same result", object = deconvolution,
    expected = deconvolution_noSignature, tolerance = 1e-1
  )
  expect_equal(
    info = "deconvolution function can return extra infos", object = ncol(deconvolution_extra_info),
    expected = ncol(deconvolution) + 3, tolerance = 1e-1
  )
  check_result <- system.file("test_results", "cibersortx_result_small.tsv",
    package = "omnideconv", mustWork = TRUE
  ) %>%
    read.csv(.,
      row.names = 1,
      check.names = FALSE, sep = "\t"
    ) %>%
    as.matrix(.) %>%
    .[, 1:3]

  check_result <- check_result[
    sort(rownames(check_result)),
    sort(colnames(check_result))
  ]

  # check_result <- check_result[, unique(cell_annotations_small)]
  expect_equal(
    info = "deconvolution result is correct", object = deconvolution,
    expected = check_result, tolerance = 1e-3
  )

  expect_equal(
    info = "deconvolution result (one-step) is correct", object = deconvolution_noSignature,
    expected = check_result, tolerance = 1e-3
  )

  expect_equal(
    info = "deconvolution result with one bulk sample throws no error",
    object = nrow(deconvolute(bulk_small_one_sample, cibersort_model, method = "cibersortx")),
    expected = 1
  )
})

test_that("Scaden deconvolution works", {
  model <- build_model(sc_object_small, cell_annotations_small,
    method = "scaden",
    bulk_gene_expression = bulk_small, samples = 10, cells = 5,
    steps = 150, verbose = F
  )

  deconvolution <- deconvolute(bulk_small, model = model, method = "scaden")

  expect_equal(
    info = "deconvolution contains same samples as in bulk (not same order)",
    object = sort(rownames(deconvolution)), expected = sort(colnames(bulk_small))
  )
  expect_equal(
    info = "deconvolution result with one bulk sample throws no error",
    object = nrow(deconvolute(bulk_small_one_sample, model = model, method = "scaden")),
    expected = 1
  )
})

test_that("Autogenes deconvolution with signature works", {
  # files <- file.info(list.files(tempdir(), full.names = T, pattern = "\\.pickle$"))
  # skip_if(nrow(files) == 0, message = "skipping autogenes deconvolution")
  # model <- rownames(files)[which.max(files$mtime)]
  model <- build_model(sc_object_small, cell_annotations_small, "autogenes")
  deconvolution <- deconvolute(bulk_small, model,
    method = "autogenes",
    single_cell_object = sc_object_small,
    cell_type_annotations = cell_annotations_small
  )
  expect_equal(
    info = "deconvolution contains same samples as in bulk (not same order)",
    object = sort(rownames(deconvolution)), expected = sort(colnames(bulk_small))
  )


  check_result <- system.file("test_results", "autogenes_result_small_new.csv",
    package = "omnideconv", mustWork = TRUE
  ) %>%
    read.csv(.,
      row.names = 1,
      check.names = FALSE,
    ) %>%
    as.matrix(.)
  expect_equal(
    info = "deconvolution result is correct", object = deconvolution,
    expected = check_result, tolerance = 1e-1
  )
  expect_equal(
    info = "deconvolution result with one bulk sample throws no error",
    object = nrow(deconvolute(bulk_small_one_sample, model,
      method = "autogenes",
      single_cell_object = sc_object_small,
      cell_type_annotations = cell_annotations_small
    )),
    expected = 1
  )
})

test_that("Autogenes deconvolution without signature works", {
  deconvolution <- deconvolute(
    single_cell_object = sc_object_small,
    bulk_gene_expression = bulk_small,
    cell_type_annotations = cell_annotations_small,
    model = NULL,
    method = "autogenes"
  )
  expect_equal(
    info = "deconvolution contains same samples as in bulk (not same order)",
    object = sort(rownames(deconvolution)), expected = sort(colnames(bulk_small))
  )

  check_result <- system.file("test_results", "autogenes_result_small_new.csv",
    package = "omnideconv", mustWork = TRUE
  ) %>%
    read.csv(.,
      row.names = 1,
      check.names = FALSE,
    ) %>%
    as.matrix(.)
  expect_equal(
    info = "deconvolution result is correct", object = deconvolution,
    expected = check_result, tolerance = 1e-1
  )
  expect_equal(
    info = "deconvolution result with one bulk sample throws no error",
    object = nrow(deconvolute(
      single_cell_object = sc_object_small,
      bulk_gene_expression = bulk_small_one_sample,
      cell_type_annotations = cell_annotations_small,
      model = NULL,
      method = "autogenes"
    )),
    expected = 1
  )
})

test_that("MuSiC deconvolution works", {
  deconvolution <- deconvolute(bulk_small, NULL,
    method = "music",
    single_cell_object = sc_object_small,
    cell_type_annotations = cell_annotations_small,
    batch_ids = batch_ids_small
  )
  expect_equal(
    info = "deconvolution contains same samples as in bulk (not same order)",
    object = sort(rownames(deconvolution)), expected = sort(colnames(bulk_small))
  )


  check_result <- system.file("test_results", "music_result_small.csv",
    package = "omnideconv", mustWork = TRUE
  ) %>%
    read.csv(.,
      row.names = 1,
      check.names = FALSE,
    ) %>%
    as.matrix(.)
  expect_equal(
    info = "deconvolution result is correct", object = deconvolution,
    expected = check_result, tolerance = 1e-3
  )
  expect_error(
    info = "MuSiC is not appliable with just one bulk sample",
    object = nrow(deconvolute(bulk_small_one_sample, NULL,
      method = "music",
      single_cell_object = sc_object_small,
      cell_type_annotations = cell_annotations_small,
      batch_ids = batch_ids_small
    ))
  )
})


# This warning can be ignored (according to https://github.com/satijalab/seurat/issues/1249):
# Warning in irlba(A = t(x = object), nv = npcs, ...) :
# You're computing too large a percentage of total singular values, use a standard svd instead.
test_that("CPM deconvolution works", {
  deconvolution_pca <- suppressMessages(deconvolute(bulk_small, NULL,
    method = "cpm",
    single_cell_object = sc_object_small,
    cell_type_annotations = cell_annotations_small,
    cell_space = "PCA",
    no_cores = 1
  ))

  deconvolution_umap <- suppressMessages(deconvolute(bulk_small, NULL,
    method = "cpm",
    single_cell_object = sc_object_small,
    cell_type_annotations = cell_annotations_small,
    cell_space = "UMAP",
    no_cores = 1
  ))

  deconvolution_tsne <- suppressMessages(deconvolute(bulk_small, NULL,
    method = "cpm",
    single_cell_object = sc_object_small,
    cell_type_annotations = cell_annotations_small,
    cell_space = "TSNE",
    no_cores = 1
  ))
  expect_equal(
    info = "deconvolution_pca contains same samples as in bulk (not same order)",
    object = sort(rownames(deconvolution_pca)), expected = sort(colnames(bulk_small))
  )

  expect_equal(
    info = "deconvolution_umap contains same samples as in bulk (not same order)",
    object = sort(rownames(deconvolution_umap)), expected = sort(colnames(bulk_small))
  )

  expect_equal(
    info = "deconvolution_tsne contains same samples as in bulk (not same order)",
    object = sort(rownames(deconvolution_tsne)), expected = sort(colnames(bulk_small))
  )
  expect_error(
    info = "CPM is not appliable with just one bulk sample",
    object = deconvolute(bulk_small_one_sample, NULL,
      method = "cpm",
      single_cell_object = sc_object_small,
      cell_type_annotations = cell_annotations_small,
      cell_space = "PCA"
    )
  )
})


test_that("SCDC deconvolution works", {
  deconvolution <- deconvolute(bulk_small, NULL,
    method = "scdc", single_cell_object = sc_object_small,
    cell_type_annotations = cell_annotations_small,
    batch_ids = batch_ids_small
  )
  expect_equal(
    info = "deconvolution contains same samples as in bulk (not same order)",
    object = sort(rownames(deconvolution)), expected = sort(colnames(bulk_small))
  )


  check_result <- system.file("test_results", "scdc_result_small.csv",
    package = "omnideconv", mustWork = TRUE
  ) %>%
    read.csv(.,
      row.names = 1,
      check.names = FALSE,
    ) %>%
    as.matrix(.)
  expect_equal(
    info = "deconvolution result is correct", object = deconvolution,
    expected = check_result, tolerance = 1e-3
  )
  expect_error(
    info = "scdc is not appliable with just one bulk sample",
    object = deconvolute(bulk_small_one_sample, NULL,
      method = "scdc", single_cell_object = sc_object_small,
      cell_type_annotations = cell_annotations_small,
      batch_ids = batch_ids_small
    )
  )


  # deconvolution_ensemble <- deconvolute(bulk_small, NULL,
  #  method = "scdc",
  #  single_cell_object = list(
  #    single_cell_data,
  #    sc_object_small
  #  ),
  #  cell_type_annotations = list(
  #    cell_type_annotations,
  #    cell_annotations_small
  #  ),
  #  batch_ids = list(batch_ids, batch_ids_small)
  # )
  # expect_equal(
  #  info = "deconvolution contains same samples as in bulk (not same order)",
  #  object = sort(rownames(deconvolution_ensemble)), expected = sort(colnames(bulk_small))
  # )
  #
  # check_result <- as.matrix(read.csv("test_results", "scdc_result_ensemble.csv",
  #  row.names = 1,
  #  check.names = FALSE
  # ))
  # expect_equal(
  #  info = "deconvolution result is correct", object = deconvolution_ensemble,
  #  expected = check_result
  # )
})

test_that("CDSeq deconvolution works", {
  deconvolution <- deconvolute(bulk_small,
    model = NULL,
    method = "cdseq",
    single_cell_object = sc_object_small,
    cell_type_annotations = cell_annotations_small,
    batch_ids = batch_ids_small,
    no_cores = 1
  )
  expect_equal(
    info = "deconvolution contains same samples as in bulk (not same order)",
    object = sort(rownames(deconvolution)), expected = sort(colnames(bulk_small))
  )
  expect_equal(
    info = "deconvolution result with one bulk sample throws no error",
    object = nrow(deconvolute(bulk_small_one_sample,
      model = NULL,
      method = "cdseq",
      single_cell_object = sc_object_small,
      cell_type_annotations = cell_annotations_small,
      batch_ids = batch_ids_small,
      no_cores = 1
    )),
    expected = 1
  )
})

test_that("BayesPrism deconvolution works", {
  set.seed(123)
  deconvolution <- deconvolute(
    bulk_gene_expression = bulk_small, NULL,
    method = "bayesprism",
    single_cell_object = sc_object_small,
    cell_type_annotations = cell_annotations_small
  )
  expect_equal(
    info = "deconvolution contains same samples as in bulk (not same order)",
    object = sort(rownames(deconvolution)), expected = sort(colnames(bulk_small))
  )


  check_result <- system.file("test_results", "bayesprism_result_small.csv",
    package = "omnideconv", mustWork = TRUE
  ) %>%
    read.csv(.,
      row.names = 1,
      check.names = FALSE,
    ) %>%
    as.matrix(.)
  expect_equal(
    info = "deconvolution result is correct", object = deconvolution[, sort(colnames(deconvolution))],
    expected = check_result[, sort(colnames(check_result))], tolerance = 1e-1
  )
})
