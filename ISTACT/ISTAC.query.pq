let
    Source = ISTAC.Contents(),
    Clasificaciones = Source{[Key="Clasificaciones"]}[Data],
    Clasificaciones1 = Clasificaciones{[Key="Clasificaciones"]}[Data],
    VRF_DEMOGRAFICAS = Clasificaciones1{[Key="VRF_DEMOGRAFICAS"]}[Data],
    VR_SEXO = VRF_DEMOGRAFICAS{[Key="VR_SEXO"]}[Data]
in
    VR_SEXO