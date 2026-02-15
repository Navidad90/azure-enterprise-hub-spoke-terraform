# Enterprise Azure Hub-Spoke Network Architecture (Production-Ready Baseline)

---

## 1. Executive Summary

This project demonstrates the design and implementation of a production-grade Azure networking foundation using Terraform.

The objective was to architect a secure, segmented, observable, and scalable cloud network capable of hosting containerized workloads (AKS) while enforcing:

- Centralized traffic control  
- Controlled egress  
- Enterprise-level monitoring  
- Zero Trust segmentation  
- Infrastructure as Code governance  

This architecture mirrors real-world enterprise cloud platform design patterns.

---

## 2. Architecture Overview

The solution implements a Hub-Spoke topology:

- Hub VNet (shared services & security boundary)
- Spoke VNet (AKS workload subnet)
- Bidirectional VNet Peering
- Forced egress via UDR (0.0.0.0/0 → Hub)
- Dedicated `AzureFirewallSubnet`
- Network Security Groups
- Log Analytics Workspace
- Diagnostic Settings
- NSG Flow Logs
- Private DNS Zone
- DDoS Protection Plan

---

## 3. High-Level Architecture Diagram

subgraph Hub VNet (vnet-hub-prod-gwc)
    SHARED[subnet-shared-services]
    FW[AzureFirewallSubnet]
end

subgraph Spoke VNet (vnet-spoke-aks-prod-gwc)
    AKS[subnet-aks-nodes]
end

AKS -->|0.0.0.0/0 UDR| FW
AKS <-->|Peering| SHARED
FW --> Internet[(Internet)]

HubDiag[Diagnostic Settings]
SpokeDiag[Diagnostic Settings]

HubDiag --> LAW[Log Analytics Workspace]
SpokeDiag --> LAW

NSGHub[NSG Hub]
NSGSpoke[NSG Spoke]

NSGHub --> FlowLogsHub[NSG Flow Logs]
NSGSpoke --> FlowLogsSpoke[NSG Flow Logs]

FlowLogsHub --> Storage[(Flow Log Storage)]
FlowLogsSpoke --> Storage

DDOS[DDoS Protection Plan] --> SHARED

PrivateDNS[Private DNS Zone\nprivatelink.database.windows.net]
PrivateDNS --> SHARED
PrivateDNS --> AKS

---

## 4. Terraform Project Structure

This project follows a layered enterprise Terraform architecture:

terraform/
├── modules/
│   └── network/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
├── platform/
│   └── network/
│       ├── main.tf
│       ├── hub/
│       │   └── main.tf
│       └── spoke-aks-prod/
│           └── main.tf
│
└── environments/
    └── prod/
        └── network/
            ├── main.tf
            ├── variables.tf
            ├── backend.tf
            └── provider.tf
Layer Explanation
modules/
Reusable building blocks (VNets, subnets, outputs).

platform/
Defines topology and enterprise controls (peering, routing, logging, DNS, DDoS, flow logs).

environments/
Environment-specific deployment configuration (production in this case).

This separation ensures:

Reusability
Environment isolation
Multi-environment scalability
Enterprise maintainability

----

## 5. Deployment Workflow

Infrastructure was deployed using controlled Terraform execution:

terraform init
terraform validate
terraform plan -out=prod.plan
terraform apply prod.plan
terraform state list
Execution plans were saved before apply to ensure deterministic and auditable deployments.

---

## 6. Security & Governance Controls

Control	Purpose
Hub-Spoke Segmentation	Workload isolation
NSGs	Traffic filtering
UDR (0.0.0.0/0 → Hub)	Controlled outbound traffic
AzureFirewallSubnet	Central inspection boundary
Diagnostic Settings	Network observability
NSG Flow Logs	Traffic visibility & analytics
Log Analytics	Central monitoring platform
Private DNS	Secure private name resolution
DDoS Plan	Layer 3/4 volumetric protection

---

## 7. Design Decisions

Why Hub-Spoke?
Industry-standard enterprise network segmentation model.

Why Forced Egress?
Ensures outbound traffic control and inspection capability.

Why Modular Terraform?
Promotes reuse, reduces duplication, and supports multi-environment deployment strategies.

Why Observability by Default?
Security without visibility is incomplete.

---

## 8. Enterprise Readiness

The architecture is designed to support future enhancements:

Azure Firewall Policies
Private Endpoints
AKS Private Cluster Integration
Policy-as-Code (Azure Policy / OPA)
CI/CD automation

---

## 9. Skills Demonstrated

Azure Enterprise Network Architecture
Hub-Spoke Design
Secure AKS Networking
Controlled Egress Engineering
Terraform Modular Architecture
Infrastructure Governance
Production Observability
Private DNS Integration
DDoS Protection Strategy

---
## Architecture Diagram

![Enterprise Azure Hub-Spoke Architecture](diagrams/hub-spoke-architecture.png)

