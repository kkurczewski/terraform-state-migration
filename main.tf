resource "null_resource" "bar" {

}

resource "null_resource" "baz" {

}

resource "random_string" "random_str" {
  length = 4
}