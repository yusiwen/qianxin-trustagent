group "default" {
  targets = ["qianxin-trustagent"]
}
target "qianxin-trustagent" {
  context = "."
  dockerfile = "Dockerfile"
  tags = ["yusiwen/qianxin-trustagent:3.4.1.1010.15"]
  args = {
  }
  no-cache = false
  platforms = ["linux/amd64", "linux/arm64"]
}

target "qianxin-trustagent-3.3" {
  context = "."
  dockerfile = "Dockerfile-3.3"
  tags = ["yusiwen/qianxin-trustagent:3.3.1.1155"]
  args = {
  }
  no-cache = false
  platforms = ["linux/amd64", "linux/arm64"]
}