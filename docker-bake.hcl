group "default" {
  targets = ["qianxin-trustagent-3_5"]
}

target "qianxin-trustagent-3_5" {
  context = "."
  dockerfile = "Dockerfile-3.5"
  tags = ["yusiwen/qianxin-trustagent:3.5.1.1003.62"]
  args = {
    TRUSTAGENT_VERSION = "3.5.1.1003.62"
  }
  no-cache = false
  platforms = ["linux/amd64", "linux/arm64"]
}

target "qianxin-trustagent-3_4" {
  context = "."
  dockerfile = "Dockerfile-3.4"
  tags = ["yusiwen/qianxin-trustagent:3.4.1.1010.15"]
  args = {
    TRUSTAGENT_VERSION = "3.4.1.1010.15"
  }
  no-cache = false
  platforms = ["linux/amd64", "linux/arm64"]
}

target "qianxin-trustagent-3_3" {
  context = "."
  dockerfile = "Dockerfile-3.3"
  tags = ["yusiwen/qianxin-trustagent:3.3.1.1155"]
  args = {
    TRUSTAGENT_VERSION = "3.3.1.1155"
  }
  no-cache = false
  platforms = ["linux/amd64", "linux/arm64"]
}
