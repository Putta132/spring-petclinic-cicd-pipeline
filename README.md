# 🚀 Spring PetClinic — Jenkins CI/CD Pipeline

A fully automated CI/CD pipeline for the **Spring PetClinic** application built on AWS. The pipeline compiles, tests, performs static code analysis, packages, stores artifacts, and deploys — all triggered from a single Jenkins job.

---

## 🏗️ Pipeline Architecture

```
Developer pushes code to GitHub
           │
           ▼
     [ Jenkins EC2 ]
           │
     ┌─────▼──────┐
     │   Compile   │  mvn clean compile
     └─────┬───────┘
           │
     ┌─────▼──────┐
     │    Test     │  mvn test (JUnit reports)
     └─────┬───────┘
           │
     ┌─────▼────────────┐
     │ Code Quality      │  SonarQube analysis
     │ [ SonarQube EC2 ] │  + Quality Gate check
     └─────┬─────────────┘
           │
     ┌─────▼──────┐
     │   Package   │  mvn package → .WAR file
     └─────┬───────┘
           │
     ┌─────▼──────────────┐
     │ Upload to Nexus     │  mvn deploy
     │ [ Nexus EC2 ]       │  Artifact stored in repository
     └─────┬───────────────┘
           │
     ┌─────▼──────────────┐
     │ Deploy to Tomcat    │  WAR deployed via Tomcat Deploy Plugin
     │ [ Tomcat EC2 ]      │  App live on port 8080
     └─────────────────────┘
```

---

## ☁️ Infrastructure

| Server | Tool | EC2 Type | Port |
|---|---|---|---|
| Jenkins Server | Jenkins 2.x | t3.medium | 8080 |
| Code Quality Server | SonarQube 10.x | t3.medium | 9000 |
| Artifact Repository | Nexus OSS 3.x | t3.medium | 8081 |
| Application Server | Apache Tomcat 10.x | t3.micro | 8080 |

All EC2 instances deployed on **AWS ap-south-1** with least-privilege Security Groups — each tool only accepts traffic from the sources that need it.

---

## 🔐 Security Group Design

| Instance | Inbound Rule |
|---|---|
| Jenkins | Port 8080, Port 22 |
| SonarQube | Port 9000 |
| Nexus | Port 8081 |
| Tomcat | Port 8080 |

SonarQube and Nexus are **not publicly accessible** — only Jenkins can reach them.

---

## 📂 Repository Structure

```
spring-petclinic-cicd-pipeline/
├── jenkins/
│   └── Jenkinsfile              # Declarative pipeline — all 7 stages
├── scripts/
│   ├── jenkins-setup.sh         # EC2 user-data: Jenkins + Java + Maven
│   ├── sonarqube-setup.sh       # EC2 user-data: SonarQube 10.x
│   ├── nexus-setup.sh           # EC2 user-data: Nexus OSS 3.x
│   └── tomcat-setup.sh          # EC2 user-data: Tomcat 10.x + Manager config
├── terraform/
│   ├── main.tf                  # VPC, SGs, 4 EC2 instances
│   ├── variables.tf
│   └── terraform.tfvars.example
├── screenshots/                 # Console + pipeline screenshots
└── README.md
```

---

## ⚙️ Pipeline Stages

| Stage | Tool | What it does |
|---|---|---|
| **Checkout** | Git | Clones source code from GitHub |
| **Compile** | Maven | `mvn clean compile` — checks for syntax/build errors |
| **Test** | Maven + JUnit | `mvn test` — runs unit tests, publishes JUnit report |
| **Code Quality** | SonarQube | Static analysis — bugs, vulnerabilities, code smells |
| **Quality Gate** | SonarQube | Fails the pipeline if code quality threshold not met |
| **Package** | Maven | `mvn package` — produces `.WAR` file |
| **Upload to Nexus** | Nexus | `mvn deploy` — stores versioned artifact in Nexus repo |
| **Deploy to Tomcat** | Tomcat Plugin | Deploys WAR to Tomcat at `/petclinic` context path |

---

## 🚀 Deploy Infrastructure with Terraform

```bash
cd terraform/

# 1. Set your values
cp terraform.tfvars.example terraform.tfvars
# Edit: key_name, allowed_ssh_cidr

# 2. Init and apply
terraform init
terraform plan
terraform apply

# 3. Get all server URLs
terraform output
```

Output example:
```
jenkins_url   = "http://13.x.x.x:8080"
sonarqube_url = "http://13.x.x.x:9000"
nexus_url     = "http://13.x.x.x:8081"
tomcat_url    = "http://13.x.x.x:8080"
```

> Destroy when done: `terraform destroy`

---

## ⚙️ Resources Used

### 1. Jenkins EC2
- Launch t3.medium, Ubuntu 22.04, run `scripts/jenkins-setup.sh` as user-data
- Install plugins: **Maven Integration**, **SonarQube Scanner**, **Nexus Artifact Uploader**, **Deploy to container**
- Configure: JDK17, Maven3 under Global Tool Configuration
- Add credentials: `nexus-credentials`, `tomcat-credentials` in Jenkins Credentials Manager
- Add SonarQube server under Manage Jenkins → Configure System

### 2. SonarQube EC2
- Launch t3.medium, run `scripts/sonarqube-setup.sh` as user-data
- Login at `http://<IP>:9000` (admin/admin → change password)
- Generate token → add to Jenkins as SonarQube credential

### 3. Nexus EC2
- Launch t3.medium, run `scripts/nexus-setup.sh` as user-data
- Login at `http://<IP>:8081`
- Create a Maven hosted repository named `spring-petclinic-releases`
- Add Nexus credentials to Jenkins

### 4. Tomcat EC2
- Launch t3.micro, run `scripts/tomcat-setup.sh` as user-data
- Manager app configured with `prateek/1234`
- Add Tomcat credentials to Jenkins

### 5. Jenkins Pipeline Job
- New Item → Pipeline
- Pipeline Definition → Pipeline script from SCM
- SCM: Git → paste this repo URL
- Script Path: `jenkins/Jenkinsfile`
- Click **Build Now**

---

## 📸 Screenshots

| Component | Folder |
|---|---|
| Jenkins pipeline stages (all green) | `screenshots/jenkins/` |
| SonarQube analysis report | `screenshots/sonarqube/` |
| Nexus artifact uploaded | `screenshots/nexus/` |
| PetClinic app live on Tomcat | `screenshots/tomcat/` |
| Full pipeline console output | `screenshots/pipeline/` |

---

## 📈 Future Enhancements

- [ ] GitHub Webhook to auto-trigger pipeline on every push
- [ ] Docker image build + push to ECR after package stage
- [ ] Deploy to ECS/EKS instead of Tomcat
- [ ] Email/Slack notifications on pipeline success/failure
- [ ] Pipeline as multi-branch for feature branch support

---

## 🔐 Security Recommendations

> These are observed gaps from the current setup. Addressing these before moving to production is strongly recommended.

1. **SonarQube Security Rating is D** — There are open security issues flagged by SonarQube analysis. Review and fix all critical/blocker security hotspots before deploying to production.
2. **Enable HTTPS/TLS** — All services (Jenkins, SonarQube, Nexus, Tomcat) are currently running on HTTP. Set up SSL certificates (via Let's Encrypt or ACM) to encrypt traffic in transit.
3. **Restrict Security Group Rules** — Tighten EC2 inbound rules to allow only necessary ports from trusted IP ranges. Avoid `0.0.0.0/0` except where absolutely required (e.g. public-facing app).
4. **Credential Rotation** — Rotate Jenkins and Nexus credentials regularly. Always store secrets in **Jenkins Credentials Manager** — never hardcode passwords in the Jenkinsfile or scripts.
5. **SonarQube Embedded Database** — SonarQube is currently using its built-in H2 database which is not recommended for production. Migrate to **PostgreSQL** for reliability, persistence, and better performance.

---

## 🛠️ Troubleshooting

| Issue | Fix |
|---|---|
| SonarQube Quality Gate not appearing | Ensure the `sonar.projectKey` matches the project key configured in SonarQube |
| Nexus upload fails | Verify `credentialsId` in Jenkinsfile matches the stored Nexus credentials ID in Jenkins |
| Maven build slow | Add Maven cache or configure a local `.m2` mirror to avoid re-downloading dependencies |
| Pipeline doesn't trigger | Check Git webhook or polling configuration in the Jenkins job settings |
| SonarQube takes too long to start | SonarQube needs at least 2GB RAM — ensure you are using t3.medium or higher |
| Tomcat deploy fails | Confirm `manager-script` role is assigned to the Tomcat user in `tomcat-users.xml` |
| Jenkins can't reach SonarQube/Nexus | Verify Security Group inbound rules allow traffic from the Jenkins EC2 Security Group |

---

---

## 👨‍💻 Author

**Prateek Kulkarni**
