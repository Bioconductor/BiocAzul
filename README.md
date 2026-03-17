
# BiocAzul

# Installation

Install the development version of the `BiocAzul` package from GitHub
using the following:

``` r
if (!require("BiocManager", quietly = TRUE))
    install.packages("BiocManager")
BiocManager::install("Bioconductor/BiocAzul")
```

# Package Loading

``` r
library(BiocAzul)
```

# Introduction

The `BiocAzul` package provides an interface to the Azul API, which is
used to index data from the Human Cell Atlas (HCA) and the AnVIL Data
Explorer. Azul provides a convenient query interface for searching and
retrieving data from these projects.

# Basic Usage

To get started, create an `Azul` service object. By default, it connects
to the Human Cell Atlas service.

``` r
hca <- Azul()
hca
#> service: azul
#> host: service.azul.data.humancellatlas.org
#> tags(); use azul$<tab completion>:
#> # A tibble: 25 × 3
#>    tag       operation                                                       summary                                        
#>    <chr>     <chr>                                                           <chr>                                          
#>  1 Auxiliary Basic_health_check                                              Basic health check                             
#>  2 Auxiliary Cached_health_check_for_continuous_monitoring                   Cached health check for continuous monitoring  
#>  3 Auxiliary Complete_health_check                                           Complete health check                          
#>  4 Auxiliary Describe_current_version_of_this_REST_API                       Describe current version of this REST API      
#>  5 Auxiliary Fast_health_check                                               Fast health check                              
#>  6 Auxiliary Redirect_to_the_Swagger_UI_for_interactive_use_of_this_REST_API Redirect to the Swagger UI for interactive use…
#>  7 Auxiliary Return_OpenAPI_specifications_for_this_REST_API                 Return OpenAPI specifications for this REST API
#>  8 Auxiliary Robots_Exclusion_Protocol                                       Robots Exclusion Protocol                      
#>  9 Auxiliary Selective_health_check                                          Selective health check                         
#> 10 Auxiliary Static_files_needed_for_the_Swagger_UI                          Static files needed for the Swagger UI         
#> # ℹ 15 more rows
#> tag values:
#>   Auxiliary, Index, Manifests, Repository
#> schemas():
```

## Connecting to the AnVIL Data Explorer

To connect to the AnVIL Data Explorer instead, specify the provider when
creating the `Azul` object.

``` r
anvil <- Azul(provider = "anvil")
anvil
#> service: azul
#> host: service.explore.anvilproject.org
#> tags(); use azul$<tab completion>:
#> # A tibble: 25 × 3
#>    tag       operation                                                       summary                                        
#>    <chr>     <chr>                                                           <chr>                                          
#>  1 Auxiliary Basic_health_check                                              Basic health check                             
#>  2 Auxiliary Cached_health_check_for_continuous_monitoring                   Cached health check for continuous monitoring  
#>  3 Auxiliary Complete_health_check                                           Complete health check                          
#>  4 Auxiliary Describe_current_version_of_this_REST_API                       Describe current version of this REST API      
#>  5 Auxiliary Fast_health_check                                               Fast health check                              
#>  6 Auxiliary Redirect_to_the_Swagger_UI_for_interactive_use_of_this_REST_API Redirect to the Swagger UI for interactive use…
#>  7 Auxiliary Return_OpenAPI_specifications_for_this_REST_API                 Return OpenAPI specifications for this REST API
#>  8 Auxiliary Robots_Exclusion_Protocol                                       Robots Exclusion Protocol                      
#>  9 Auxiliary Selective_health_check                                          Selective health check                         
#> 10 Auxiliary Static_files_needed_for_the_Swagger_UI                          Static files needed for the Swagger UI         
#> # ℹ 15 more rows
#> tag values:
#>   Auxiliary, Index, Manifests, Repository
#> schemas():
```

Note that the `host` field in the objects output changes to reflect the
AnVIL Data Explorer service.

## Listing Catalogs

Azul organizes data into catalogs. You can list the available catalogs
using `listCatalogs()`.

``` r
listCatalogs(hca)
#> [1] "dcp57"    "dcp57-it" "dcp58"    "dcp58-it" "lm10"     "lm10-it"
```

## Exploring Projects

To get a quick overview of the projects in a catalog, use
`projectTable()`. This returns a `tibble` with project names and their
corresponding IDs.

``` r
projects <- projectTable(hca, catalog = "dcp57")
head(projects)
#> # A tibble: 6 × 3
#>   term                                               count projectId                           
#>   <chr>                                              <int> <chr>                               
#> 1 -Human-10x3pv2--21                                     1 888f1766-4c84-43bb-8717-b5f9d2046097
#> 2 1M Neurons                                             1 74b6d569-3b11-42ef-b6b1-a0454522b4a0
#> 3 AIDA                                                   1 f0f89c14-7460-4bab-9d42-22228a91f185
#> 4 AIDA_DataFreeze_v2_JP                                  1 35d5b057-3daf-4ccd-8112-196194598893
#> 5 AIDA_DataFreeze_v2_TH                                  1 76bc0e97-8cae-43d4-a647-477a13be47f9
#> 6 ASingle-CellAtlasOfHumanPediatricLiverRevealsAge-R     1 febdaddd-ad3c-4f4a-820f-ade15c48545a
```

## Exploring Facets

Azul data is organized by facets, which are attributes you can use to
filter and group data. You can list the available facets for a catalog
using `availableFacets()`.

``` r
facets <- availableFacets(hca, catalog = "dcp57")
head(facets)
#> [1] "organ"              "sampleEntityType"   "dataUseRestriction" "project"            "sampleDisease"     
#> [6] "nucleicAcidSource"
```

You can also get a summary of values for a specific facet using
`facetTable()`.

``` r
facetTable(hca, facet = "genusSpecies", catalog = "dcp57")
#> # A tibble: 3 × 2
#>   term                   count
#>   <chr>                  <int>
#> 1 Homo sapiens             506
#> 2 Mus musculus              55
#> 3 canis lupus familiaris     1
```

# Filtering and Queries

The `makeFilter()` function provides a convenient way to create filters
for querying the Azul API. It uses a formula-based syntax to define the
filter criteria.

``` r
filter <- makeFilter(
    ~  specimenOrgan == "brain" &
        genusSpecies == "Mus musculus" &
        fileFormat == "h5"
)
filter
#> $specimenOrgan
#> $specimenOrgan$is
#> [1] "brain"
#> 
#> 
#> $genusSpecies
#> $genusSpecies$is
#> [1] "Mus musculus"
#> 
#> 
#> $fileFormat
#> $fileFormat$is
#> [1] "h5"
```

This filter can be used in other functions that interact with the Azul
API.

# Integration with Terra

One of the main features of `BiocAzul` is the ability to import data
directly into a Terra workspace. This is done using the
`importToTerra()` function.

Note: This step requires a Terra workspace and appropriate permissions.
The following code is for demonstration purposes and is not executed in
this vignette.

``` r
importToTerra(
    hca,
    namespace = "your-terra-namespace",
    name = "your-terra-workspace",
    catalog = "dcp57",
    filters = filter
)
```

This function will create a manifest based on the filters, initiate an
import job in Terra, and poll for its completion.

# Session Information

<details>

<summary>

Click to see session information
</summary>

``` r
sessionInfo()
#> R Under development (unstable) (2025-10-28 r88973)
#> Platform: x86_64-pc-linux-gnu
#> Running under: Ubuntu 24.04.4 LTS
#> 
#> Matrix products: default
#> BLAS/LAPACK: /usr/lib/x86_64-linux-gnu/openblas-pthread/libopenblasp-r0.3.26.so;  LAPACK version 3.12.0
#> 
#> locale:
#>  [1] LC_CTYPE=en_US.UTF-8       LC_NUMERIC=C              
#>  [3] LC_TIME=en_US.UTF-8        LC_COLLATE=en_US.UTF-8    
#>  [5] LC_MONETARY=en_US.UTF-8    LC_MESSAGES=en_US.UTF-8   
#>  [7] LC_PAPER=en_US.UTF-8       LC_NAME=C                 
#>  [9] LC_ADDRESS=C               LC_TELEPHONE=C            
#> [11] LC_MEASUREMENT=en_US.UTF-8 LC_IDENTIFICATION=C       
#> 
#> time zone: America/New_York
#> tzcode source: system (glibc)
#> 
#> attached base packages:
#> [1] stats     graphics  grDevices utils     datasets  methods  
#> [7] base     
#> 
#> other attached packages:
#> [1] tinytest_1.4.1      BiocManager_1.30.27 BiocAzul_0.99.11   
#> [4] AnVIL_1.23.7        AnVILBase_1.5.1     dplyr_1.1.4        
#> [7] colorout_1.3-2     
#> 
#> loaded via a namespace (and not attached):
#>  [1] xfun_0.56            httr2_1.2.2         
#>  [3] htmlwidgets_1.6.4    devtools_2.4.6      
#>  [5] remotes_2.5.0        vctrs_0.6.5         
#>  [7] tools_4.6.0          generics_0.1.4      
#>  [9] parallel_4.6.0       curl_7.0.0          
#> [11] tibble_3.3.0         pkgconfig_2.0.3     
#> [13] BiocBaseUtils_1.13.0 rapiclient_0.1.8    
#> [15] desc_1.4.3           lifecycle_1.0.4     
#> [17] compiler_4.6.0       credentials_2.0.3   
#> [19] BiocStyle_2.39.0     codetools_0.2-20    
#> [21] BiocAddins_0.99.26   httpuv_1.6.16       
#> [23] htmltools_0.5.9      sys_3.4.3           
#> [25] usethis_3.2.1        yaml_2.3.12         
#> [27] later_1.4.4          pillar_1.11.1       
#> [29] tidyr_1.3.1          GCPtools_1.1.0      
#> [31] ellipsis_0.3.2       openssl_2.3.4       
#> [33] rsconnect_1.7.0      DT_0.34.0           
#> [35] cachem_1.1.0         sessioninfo_1.2.3   
#> [37] mime_0.13            tidyselect_1.2.1    
#> [39] digest_0.6.39        purrr_1.2.0         
#> [41] fastmap_1.2.0        cli_3.6.5           
#> [43] magrittr_2.0.4       utf8_1.2.6          
#> [45] pkgbuild_1.4.8       withr_3.0.2         
#> [47] promises_1.5.0       rappdirs_0.3.4      
#> [49] rmarkdown_2.30       lambda.r_1.2.4      
#> [51] httr_1.4.7           otel_0.2.0          
#> [53] futile.logger_1.4.9  askpass_1.2.1       
#> [55] memoise_2.0.1        shiny_1.12.1        
#> [57] evaluate_1.0.5       knitr_1.51          
#> [59] miniUI_0.1.2         rlang_1.1.6         
#> [61] futile.options_1.0.1 gert_2.3.1          
#> [63] Rcpp_1.1.1           xtable_1.8-4        
#> [65] glue_1.8.0           formatR_1.14        
#> [67] pkgload_1.4.1        rstudioapi_0.18.0   
#> [69] jsonlite_2.0.0       R6_2.6.1            
#> [71] fs_1.6.6
```

</details>
