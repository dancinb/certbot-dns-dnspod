# certbot-dns-dnspod
使用腾讯云TCCLI命令行工具集成的Certbot DNS验证脚本

> 此脚本可以集成到 Certbot 用于实现DNS记录的创建和删除。方法类似于[certbot-dns-aliyun](https://github.com/justjavac/certbot-dns-aliyun)。

## 原理

当我们使用 Certbot 申请通配符证书（`*.example.com`）时，我们需要手动添加 TXT 记录到 DNSPod。每个 Certbot 申请的证书有效期为 3 个月，虽然 Certbot 提供了贴心的自动续期命令，但是当我们把自己续期命令配置为定时任务时，我们无法手动添加 TXT 记录。

好在 Certbot 提供了一个 hook，可以编写一个 Shell 脚本，让脚本调用 DNS 服务商的 API 接口，动态添加 TXT 记录。

## 安装

1. [安装 TCCLI 工具](https://cloud.tencent.com/document/product/440)

   ```shell
   # 准备 python3-pip
   sudo apt install python3-pip
   # 使用 pip 全局安装 tccli 到系统目录
   sudo pip install tccli
   # TCCLI 配置方法
   # 在交互模式中指定账户名 certbot
   sudo tccli configure --profile certbot
   # 填写云 API 密钥 SecretId
   # 填写云 API 密钥 SecretKey
   # 无需更改云产品地域，默认 ap-guangzhou
   # 无需更改输出格式，默认 json
   ```
   > 👉 不知道如何获取 [云 API 密钥](https://console.cloud.tencent.com/cam/capi)？

2. 安装 certbot-dns-dnspod 插件

    ```shell
    # 下载即安装
    sudo curl -L https://cdn.jsdelivr.net/gh/openbunny/certbot-dns-dnspod/dnspod.sh -o /usr/local/bin/dnspod
    sudo chmod +x /usr/local/bin/dnspod
    # 如果你的命令行里还找不到这个脚本，可以创建一个符号链接
    sudo ln -s /usr/local/bin/dnspod /usr/bin/dnspod
    ```

## 申请证书

1. 测试是否能正确申请：

    ```shell
    sudo certbot certonly --manual \
        --preferred-challenges=dns \
        --manual-auth-hook "dnspod" \
        --manual-cleanup-hook "dnspod clean" \
        -d *.example.com -d example.com --dry-run
    ```

    正式申请时去掉 `--dry-run` 参数：

    ```shell
    sudo certbot certonly --manual \
        --preferred-challenges=dns \
        --manual-auth-hook "dnspod" \
        --manual-cleanup-hook "dnspod clean" \
        -d *.example.com -d example.com
    ```

## 证书续期

1. 手动续期

    ```shell
    sudo certbot renew --manual \
        --preferred-challenges=dns 
        --manual-auth-hook "dnspod" \
        --manual-cleanup-hook "dnspod clean" --dry-run
    ```

    如果以上命令没有错误，把 `--dry-run` 参数去掉。

2. 自动续期

    添加定时任务 crontab。

    ```shell
    sudo crontab -e
    ```

    输入

    ```txt
    30 0 * * * root certbot renew --manual --preferred-challenges=dns --manual-auth-hook "dnspod" --manual-cleanup-hook "dnspod clean" --deploy-hook "nginx -t && systemctl restart nginx"
    ```

    上面脚本中的 `--deploy-hook "sudo nginx -t && sudo systemctl restart nginx"` 表示在续期成功后自动重启 nginx。
