###############################################################################
# 
# Programador: Francisco E. Galeana G.
# 
# Fecha Creación: 25-oct-2024
# Fecha Modificación: 26-oct-2024 
# 
###############################################################################

# Llave de acceso
variable "AWS_Key" {
  description = "Llave de acceso a AWS"
  type = string
}

# Clave secreta
variable "AWS_Secret" {
  description = "Clave secreta"
  type = string
}

# Región de trabajo
variable "Region_AWS" {
  description = "Región donde desarrollaremos el proyecto"
  default = "us-east-1"
}