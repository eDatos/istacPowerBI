// Use this file to write queries to test your data connector
let
    result = ISTAC.Dataset("https://www3.gobiernodecanarias.org/istac/api/statistical-resources/v1.0/datasets/ISTAC/C00010A_000012/~latest.json")
in
    result