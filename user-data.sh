#!/bin/bash

# Install Apache
dnf install -y httpd

# Start Apache and enable it at boot
systemctl enable --now httpd

# Create the website
cat > /var/www/html/index.html <<'EOF'
<h1>My Automated AWS Cloud Engineering Project</h1>
<p>Deployed automatically using Terraform and EC2 User Data.</p>
EOF
