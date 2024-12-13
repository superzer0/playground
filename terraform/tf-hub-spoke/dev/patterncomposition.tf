# https://dev.to/darrenhorwitz1/patterncomposition-terraform-nested-for-loop-o2b

locals {
  map = {
    "foo" = ["child1", "child4"]
    "bar" = ["child2", "child5"]
    "baz" = ["child3", "child6"]
  }

  out = merge([for parentKey, parentValue in local.map : {
    for child in parentValue : "${parentKey}/${child}" => {
      value = child
    }
    }
  ]...)

  # The ellipsis at the end of the array is similar to the spread operator in Javascript , similarly in golang it's a vararg .
  # What it does is spread the three maps as args in the merge function like such merge({...},{...},{...}).
  # Because what you get (below out1) without the ellipsis (spread) is a list of objects!

  out1 = [for parentKey, parentValue in local.map : {
    for child in parentValue : "${parentKey}/${child}" => {
      value = child
    }
    }
  ] # here we get tuple

  # simple example

  out2 = merge([
    { a = 1 },
    { b = 2 },
    { c = 3 }
  ]...)

  instance_names = ["dev1", "dev2", "qa1", "qa2", "qa3", "prod1", "prod2"]

  instances = {
    dev1 = {
      instance_type = "t2.micro"
      ami_id        = "dev1ami"
    }
    dev2 = {
      instance_type = "t3.micro"
      ami_id        = "dev2ami"
    }
    dev3 = {
      instance_type = "t3.micro"
      ami_id        = "dev3ami"
    }
  }
}

output "out" {
  value = local.out
}

output "out1" {
  value = local.out1
}

output "out2" {
  value = local.out2
}
