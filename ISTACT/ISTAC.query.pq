let
    Source = ISTAC.Contents(),
    Clasificaciones = Source{[Key="Clasificaciones"]}[Data],
    VRF_DEMOGRAFICAS = Clasificaciones{[Key="VRF_DEMOGRAFICAS"]}[Data],
    VR_SEXO = VRF_DEMOGRAFICAS{[Key="VR_SEXO"]}[Data],
    #"ESTAT:CL_SEX(1.1)" = VR_SEXO{[Key="ESTAT:CL_SEX(1.1)"]}[Data]
in
    #"ESTAT:CL_SEX(1.1)"