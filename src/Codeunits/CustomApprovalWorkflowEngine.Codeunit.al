codeunit 50125 "Custom Approval WF Engine"
{
    procedure RunEvent(EventCode: Code[128]; var RecRef: RecordRef)
    var
        WorkflowManagement: Codeunit "Workflow Management";
        WorkflowSetupRec: Record "Custom Approval Workflow Setup";
    begin
        if not WorkflowSetupRec.GetByTableNo(RecRef.Number) then
            exit;
        if not WorkflowSetupRec.Enabled then
            exit;
        if WorkflowSetupRec."Workflow Code" = '' then
            exit;

        WorkflowManagement.HandleEvent(EventCode, RecRef);
    end;

    procedure GetWorkflowSetupByTable(TableId: Integer; var WorkflowSetupRec: Record "Custom Approval Workflow Setup"): Boolean
    begin
        WorkflowSetupRec.Reset();
        WorkflowSetupRec.SetRange("Table No.", TableId);
        exit(WorkflowSetupRec.FindFirst());
    end;
}
