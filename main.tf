#version:20240227142401
#中国移动云terraform模块的使用示例


terraform {
  required_version = ">= 0.14"
  required_providers {
	ecloud = {
	  source  = "ecloud/ecloud"
	  version = "= 1.0.9"
	}
  }
}

provider "ecloud" {
  access_key  = "AK******"
  secret_key = "SK******"
  region	  = "CIDC-RP-33"
}

#创建VPC
#https://ecloud.10086.cn/api/page/op-oneapi-static/#/platform/78/78?apiId=5402
resource "ecloud_vpc_order" "Terraform_VPC_1" {
  #VPC示例名称和描述内容
  name = "Terraform_VPC_1"
  #第一个子网的名称
  network_name = "Terraform_BASE_NET"
  region = "N021-SH-MHZQ01"
  specs = "high"
  cidr = "10.10.0.0/24"
  cidr_v6 = "64"
}

output "debug_output_Terraform_VPC_1" {
  value = ecloud_vpc_order.Terraform_VPC_1
}


#根据VPCID查询VPC详情
#https://ecloud.10086.cn/api/page/op-oneapi-static/#/platform/78/78?apiId=19800




##创建路由表
#variable "router_id" {}
#variable "subnet" {}
#
#resource "ecloud_vpc_router_table" "test" {
#  name      = "test_1"
#  router_id = var.router_id
#  subnet   = var.subnet
#}
#
#
#
#variable "router_id" {
#    default = ""
#}
#variable "cidr" {
#    default = ""
#}


#创建子网
resource "ecloud_vpc_network" "Terraform_vpc_subnet_1" {
  availability_zone_hints = "N021-SH-MHZQ01"
  network_name = "Terraform_subnet_1"
  network_type_enum = "VM"
  region = "N021-SH-MHZQ01"
  router_id = ecloud_vpc_order.Terraform_VPC_1.router_id
  subnets {
    cidr        = "10.10.11.0/24"
    ip_version  = "4"
    subnet_name = "Terrafome_zone1_subnet1"
  }
  subnets {
    cidr        = "64"
    ip_version  = "6"
    subnet_name = "Terrafome_zone1_subnet1"
  }
}


#创建虚拟网卡
#https://ecloud.10086.cn/api/page/op-oneapi-static/#/platform/78/78?apiId=50862
#https://ecloud.10086.cn/op-help-center/doc/article/75474
resource "ecloud_vpc_port" "Terraform_VPC_net_interface_1" {

  #网卡所属的地域
  #region = "N021-SH-MHZQ01"

  #虚拟网卡名称
  name = "Terraform_VPC_net_interface_1"

  #指定子网的ID
  network_id = ecloud_vpc_network.Terraform_vpc_subnet_1.id

  #绑定云主机的示例ID
  #bindingHostId = ""

  #是否为边缘可用区
  #edge = false

  #指定IP地址
  #ips {
  #  ipAddress = ""
  #  subnetId = ""
  #}

  #定义网卡MAC地址
  #macAddress = ""

  #网卡绑定安全组的ID
  #sgIds = ""

  #虚拟网卡类型
  #type = "VM"

}

#创建IPV4公网带宽资源
resource "ecloud_eip_ip_bandwidth" "Terraform_ipv4_bandwidth_1" {
  
  #出方向带宽大小，单位Mbps，取值范围1-10240
  bandwidth_size = 2
  
  #计费方式:按流量计费
  charge_mode_enum ="trafficCharge"
  
  #计费周期:按小时计费
  charge_period_enum  ="hour"

  #包月时长，单位为月
  #duration = 1
  
  #线路类型:移动单线(BGP模式的还没上线，暂不支持)
  ip_type = "MOBILE"

}


#创建IPV6公网带宽资源
resource "ecloud_eip_ipv6_order" "Terraform_ipv6_bandwidth_1" {
  bandwidth_size = 2
  charge_mode_enum = "trafficCharge"
  charge_period_enum = "hour"
  port_id = ecloud_vpc_port.Terraform_VPC_net_interface_1.id
  product_type = "ipv6bandwidth"
}


#将EIP和虚拟网卡做绑定动作
resource "ecloud_eip_ip_bind" "test" {
  ip_id = ecloud_eip_ip_bandwidth.Terraform_ipv4_bandwidth_1.id
  resource_id = ecloud_ecs_instance.Terraform_ECS_instance_1.id
  #resource_id = "e7da50ae-7453-46d9-82f7-1ec7a8b3700c"
  type = "vm"
}

#创建安全组资源
resource "ecloud_vpc_security_group" "Terraform_security_group_1" {

  #安全组实例名称
  name = "TF_security_group_1"

  #有状态安全组还是无状态安全组，默认传参为有状态安全组，即自动放行反向规则
  #https://ecloud.10086.cn/op-help-center/doc/article/23882
  stateful = false

  type ="VM"
}


#创建安全组规则1
resource "ecloud_vpc_security_rule" "sg-role1" {
  direction = "ingress"
  protocol = "ANY"
  #remote_security_group_id = "f14f8d40-e53d-444c-9412-6a45f4aeccb7"
  security_group_id = ecloud_vpc_security_group.Terraform_security_group_1.id
  remote_type = "cidr"
  remote_ip_prefix = "0.0.0.0/0"
  description = "入方向放通全网IPV4地址"
  ether_type = "IPv4"
}


#创建安全组规则2
resource "ecloud_vpc_security_rule" "sg-role2" {
  direction = "ingress"
  protocol = "ANY"
  #remote_security_group_id = "f14f8d40-e53d-444c-9412-6a45f4aeccb7"
  security_group_id = ecloud_vpc_security_group.Terraform_security_group_1.id
  remote_type = "cidr"
  remote_ip_prefix = "::/0"
  description = "入方向放通全网IPV6地址"
  ether_type = "IPv6"
}


#创建云主机实例
resource "ecloud_ecs_instance" "Terraform_ECS_instance_1" {

  #填写zoneDesc
	region = "N021-SH-MHZQ01"

  #计费方式为按小时结算的按量付费模式
	billing_type = "HOUR"

  #虚拟机实例簇信息
	vm_type = "common"

  #设置VCPU数量
	cpu = 1

  #设置内存大小，单位为GB
	ram = 2

  #设置系统盘大小和存储介质类型
	boot_volume {
	  size = 20
	  volume_type = "performanceOptimization"
	}

  #黑盒-image_id
  #使用镜像ID模式，可以防止镜像重名等情况，导致错误选择
  #这个接口暂时还用不了
  #image_id = "6f6561ac-a986-12ec-994b-5987e37a5290"

  #指定操作系统镜像的名称
	image_name = "Debian 11.6 64位"

  #硬编码VPC信息
  #networks {
  #指定subnet_id
  #network_id = "b97de2e0-f2ac-4016-bcbc-b0fe38a5a69f"

  #指定虚拟网卡ID
  #port_id = "e7da50ae-7453-46d9-82f7-1ec7a8b3700c"
  #}

  #上海一区双栈VPC
  networks {
    #指定subnet_id
    network_id = ecloud_vpc_network.Terraform_vpc_subnet_1.id
    
    #指定虚拟网卡ID
    port_id = ecloud_vpc_port.Terraform_VPC_net_interface_1.id
	}

  #设置实例名称
  name = "instance-1"

  #设置登录密码Taobao.org1
  #RSA加密工具 https://www.lddgo.net/encrypt/rsa
  #使用官网给出的公钥对登录密码字符串进行RSA加密后输出的base64内容作为传入参数
  #公钥信息 https://ecloud.10086.cn/api/page/op-oneapi-static/#/platform/1/1?apiId=1376&tab=DOC
  password = "sqqpVwT22RqIx13s4ZJiAC3776vx3WuzXcoiz9bMg0u52hKOjRWbOwAi4SNWrwQAeoke4hTdLcachCqJ2YaYgx+FK1oqH7c79go0qHg+trT5KOv6rvH/5M1KlZcoHmJuITK9TPpZIXZK+peLv8rzsXE8tcuYSqmbSvTcamHw42g="
  
  #指定登录密钥的名称
  #keypair_name = "ddg117"
  #keypair_name = ecloud_ecs_vm_keypair.sshkey20240125.name

  #设置订购数量
  quantity = 1

  #设置订阅时长为按量计费模式
  #duration = 0

  #黑盒-定义数据盘部分信息
  #disk{}

  #黑盒-定义数据盘部分参数信息
  #data_volume
  #{
  #    = 
  #}

  #黑盒-metadata部分信息,支持初始化传参
  #必须传入Base64加密后的数据
  #user_data = "IyEvYmluL2Jhc2gKeXVtIGluc3RhbGwgaHR0cGQgLXkKc3lzdGVtY3RsIHN0YXJ0IGh0dHBkCg=="

  #黑盒-绑定EIP的线路类型(可选参数MOBILE:中国移动单线;MULTI_LINE:优享版)
  ip {
    ip_type = "MOBILE"
  }

  #黑盒-估计是实例簇
  #product_types

  #黑盒-估计是机型代码
  #procedure_code

  #黑盒-实例描述
  #description

  #黑盒-详细参数(估计是是否安装云监控客户端之类的)
  #detail

  #黑盒-此参数估计是用于K8S主控集群或函数计算宿主机模式的创建方法
  #visible

  #黑盒
  #specs_name

  #黑盒-安全组ID
  #security_group_ids = "91e2b6bc-35ee-4b94-83fa-3c6e9841c7fb"
  security_group_ids = [ecloud_vpc_security_group.Terraform_security_group_1.id]

  #黑盒
  #order_id

  #黑盒
  #order_exts
  #order_ext_types

  #黑盒-直接指定出方向的EIP的带宽，单位Mbps,取值范围0-200或1-200
  #bandwidth = "2"

  #黑盒-实例内网hostname或者RDNS名称?
  #bind {
  #  id = "3929e21c-91f5-4b78-84d1-8e65515ac8dc"
  #}

}


output "debug_Terraform_ECS_instance_1" {
    value = ecloud_ecs_instance.Terraform_ECS_instance_1
}

output "debug_oem2" {
    value = ecloud_eip_ip_bandwidth.Terraform_ipv4_bandwidth_1
}





