codeunit 50120 "Custom Approval Workflow Mgt."
{
    procedure HasOpenApprovalEntriesForCurrentUser(RecId: RecordId): Boolean
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        ApprovalEntry.SetRange("Table ID", RecId.TableNo);
        ApprovalEntry.SetRange("Record ID to Approve", RecId);
        ApprovalEntry.SetRange("Approver ID", UserId);
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Open);
        exit(not ApprovalEntry.IsEmpty());
    end;

    procedure SendApprovalRequest(var ApprovalTesting: Record "Approval Testing")
    var
        WorkflowManagement: Codeunit "Workflow Management";
        WfEvents: Codeunit "Appr. Test. WF Events";
        RecRef: RecordRef;
    begin
        if ApprovalTesting.Status <> ApprovalTesting.Status::Open then
            exit;

        RecRef.GetTable(ApprovalTesting);
        WorkflowManagement.HandleEvent(WfEvents.RunWorkflowOnSendApprovalRequestCode(), RecRef);

        if not ApprovalTesting.Get(ApprovalTesting.PK) then
            exit;
        ApprovalTesting.Status := ApprovalTesting.Status::Pending;
        ApprovalTesting.Modify(true);
        Message('Approval request has been sent for %1.', ApprovalTesting.PK);
    end;

    procedure CancelApprovalRequest(var ApprovalTesting: Record "Approval Testing")
    var
        WorkflowManagement: Codeunit "Workflow Management";
        WfEvents: Codeunit "Appr. Test. WF Events";
        RecRef: RecordRef;
    begin
        if ApprovalTesting.Status <> ApprovalTesting.Status::Pending then
            exit;

        RecRef.GetTable(ApprovalTesting);
        WorkflowManagement.HandleEvent(WfEvents.RunWorkflowOnCancelApprovalRequestCode(), RecRef);

        if not ApprovalTesting.Get(ApprovalTesting.PK) then
            exit;
        ApprovalTesting.Status := ApprovalTesting.Status::Open;
        ApprovalTesting.Modify(true);
        Message('Approval request has been cancelled for %1.', ApprovalTesting.PK);
    end;

    procedure ApproveRecord(var ApprovalTesting: Record "Approval Testing")
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        ApprovalEntry.SetRange("Table ID", Database::"Approval Testing");
        ApprovalEntry.SetRange("Record ID to Approve", ApprovalTesting.RecordId);
        ApprovalEntry.SetRange("Approver ID", UserId);
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Open);
        if not ApprovalEntry.FindFirst() then
            Error('No open approval entry for the current user on this record.');

        ApprovalEntry.Validate(Status, ApprovalEntry.Status::Approved);
        ApprovalEntry.Modify(true);

        if not ApprovalTesting.Get(ApprovalTesting.PK) then
            exit;
        ApprovalTesting.Status := ApprovalTesting.Status::Released;
        ApprovalTesting.Modify(true);
        Message('Approval Testing: %1 has been approved.', ApprovalTesting.PK);
    end;

    procedure RejectRecord(var ApprovalTesting: Record "Approval Testing")
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        ApprovalEntry.SetRange("Table ID", Database::"Approval Testing");
        ApprovalEntry.SetRange("Record ID to Approve", ApprovalTesting.RecordId);
        ApprovalEntry.SetRange("Approver ID", UserId);
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Open);
        if not ApprovalEntry.FindFirst() then
            Error('No open approval entry for the current user on this record.');

        ApprovalEntry.Validate(Status, ApprovalEntry.Status::Rejected);
        ApprovalEntry.Modify(true);

        if not ApprovalTesting.Get(ApprovalTesting.PK) then
            exit;
        ApprovalTesting.Status := ApprovalTesting.Status::Rejected;
        ApprovalTesting.Modify(true);
    end;

    procedure OpenCodeEditor(var Setup: Record "Custom Approval Workflow Setup")
    var
        CodeEditor: Page "Code Editor Workflow AL";
    begin
        Commit();
        CodeEditor.SetSetup(Setup);
        CodeEditor.RunModal();
    end;

    procedure OpenAutoDeploy(var Setup: Record "Custom Approval Workflow Setup")
    var
        Deploy: Page "Auto Deploy Scheduler";
    begin
        Commit();
        Deploy.SetSetup(Setup);
        Deploy.RunModal();
    end;
}
