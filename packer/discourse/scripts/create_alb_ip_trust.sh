#!/usr/bin/env bash

set -euxo pipefail

cd /var/discourse

if [[ -z "${ALB_SUBNETS_LIST}" ]]; then
  echo "ALB_SUBNETS_LIST is empty" >&2
  exit 1
fi

ALB_SUBNETS_LINES=$(echo "${ALB_SUBNETS_LIST}" | tr ',' '\n' | sed 's/^/        /')

sudo tee "alb_nginx_ip.yml" > /dev/null <<EOF
run:
  - file:
      path: /tmp/add-alb-ips
      chmod: +x
      contents: |
        #!/usr/bin/env bash
        cat <<'EOF' > /tmp/alb-ips
$ALB_SUBNETS_LINES
        EOF

        CONTENTS=\$(</tmp/alb-ips sed '/^\$/d; s/^.*/set_real_ip_from &;/' | tr '\n' '\\\\' | sed 's/\\\\/\\\\n/g')

        echo "ALB IPs:"
        echo \$(echo | sed "/^/a \$CONTENTS")

        # Insert into discourse.conf
        sed -i "/sendfile on;/a \$CONTENTS\nreal_ip_recursive on;\n" /etc/nginx/conf.d/discourse.conf
        rm -f /tmp/alb-ips

  - exec: "/tmp/add-alb-ips"
  - exec: "rm /tmp/add-alb-ips"
EOF

sudo chmod 700 alb_nginx_ip.yml
