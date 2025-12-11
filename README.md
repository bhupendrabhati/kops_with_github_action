#IDP: Terraform + KOPS + Nginx (AWS ap-south-1)

**Folder Structure**
my-repo/
│
├── infra-kops/
│   ├── *.tf
│   ├── nginx-deploy.yaml
│   ├── nginx-svc.yaml
│   └── scripts/
│        └── bootstrap.sh
│
├── infra-bootstrap/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── …
│
├── scripts/
│   └── post_destroy_checklist.sh
│
├── DEPLOYMENT.md
├── README.md
│
└── .github/
     └── workflows/
          ├── bootstrap-backend.yml
          ├── infra-and-kops.yml
          └── destroy.yml
