# Delete completed TaskRun pods
oc delete pod -n travel-agency --field-selector=status.phase=Succeeded

# Delete completed PipelineRuns
oc delete pipelinerun --all -n travel-agency
