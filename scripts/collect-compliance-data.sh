#!/bin/bash
# scripts/collect-compliance-evidence.sh

mkdir -p compliance/evidence

echo "=== Collecting Compliance Evidence ===" 
date > compliance/evidence/report-$(date +%Y%m%d).txt

echo -e "\n--- Defender for Cloud Secure Score ---" >> compliance/evidence/report-$(date +%Y%m%d).txt
az security secure-score-controls list --query "[].{Control:displayName, Score:current, Max:max}" -o table >> compliance/evidence/report-$(date +%Y%m%d).txt

echo -e "\n--- Kyverno Policy Reports ---" >> compliance/evidence/report-$(date +%Y%m%d).txt
kubectl get policyreport -A -o yaml >> compliance/evidence/report-$(date +%Y%m%d).txt

echo -e "\n--- Kube-bench Results ---" >> compliance/evidence/report-$(date +%Y%m%d).txt
kubectl logs job/kube-bench -n kube-bench >> compliance/evidence/report-$(date +%Y%m%d).txt 2>/dev/null || echo "No kube-bench job found"


echo "Report saved to compliance/evidence/report-$(date +%Y%m%d).txt"