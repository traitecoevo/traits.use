# Look up location properties

Look up location properties that contain a specific search term.

## Usage

``` r
lookup_location_property(database, term)
```

## Arguments

- database:

  traits.build database (list object)

- term:

  character string for location property search term

## Value

vector containing location properties that contains search term

## Examples

``` r
austraits_lite %>% lookup_location_property("soil")
#>  [1] "soil type"                               
#>  [2] "soil P, total (mg/kg)"                   
#>  [3] "soil pH (H2O)"                           
#>  [4] "soil K (mg/kg)"                          
#>  [5] "soil N, total (ppm)"                     
#>  [6] "soil bulk density (g/cm3)"               
#>  [7] "soil cation exchange capacity (meq/kg)"  
#>  [8] "soil clay (%)"                           
#>  [9] "soil conductivity (dS/m)"                
#> [10] "soil depth to gravel or laterite (m)"    
#> [11] "soil organic carbon (%)"                 
#> [12] "soil pH, 1-10 cm"                        
#> [13] "soil sand (%)"                           
#> [14] "soil silt (%)"                           
#> [15] "soil texture"                            
#> [16] "soil water holding capacity (v/v)"       
#> [17] "soil C:N"                                
#> [18] "soil C:P"                                
#> [19] "soil N, total (%)"                       
#> [20] "soil N:P"                                
#> [21] "soil cation exchange capacity (cmol/kg)" 
#> [22] "soil exchangeable Al (cmol/kg)"          
#> [23] "soil exchangeable Ca (cmol/kg, meq/100g)"
#> [24] "soil exchangeable K (cmol/kg, meq/100g)" 
#> [25] "soil exchangeable Mg (cmol/kg, meq/100g)"
#> [26] "soil exchangeable Na (cmol/kg, meq/100g)"
#> [27] "soil pH (CaCl2)"                         
#> [28] "soil C, total (%)"                       
```
