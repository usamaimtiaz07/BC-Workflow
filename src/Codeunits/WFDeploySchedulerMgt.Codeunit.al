codeunit 50147 "WF Deploy Scheduler Mgt"
{
    Access = Public;

    procedure ScheduleDeploy(var Setup: Record "Custom Approval Workflow Setup"; EarliestStart: DateTime; Timeout: Duration)
    var
        JobQueueEntry: Record "Job Queue Entry";
        ParameterText: Text;
        EffectiveStart: DateTime;
    begin
        ValidateDeployConfiguration(Setup);

        EffectiveStart := EarliestStart;
        if EffectiveStart = 0DT then
            EffectiveStart := CurrentDateTime();

        JobQueueEntry.Init();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := Codeunit::"WF Deploy Job Runner";
        JobQueueEntry."Earliest Start Date/Time" := EffectiveStart;
        JobQueueEntry."Maximum No. of Attempts to Run" := 1;
        if Timeout > 0 then
            JobQueueEntry."Job Timeout" := Timeout;
        JobQueueEntry.Description := CopyStr(StrSubstNo('WF deploy %1', Setup."No."), 1, MaxStrLen(JobQueueEntry.Description));
        ParameterText := BuildParameterText(Setup."No.");
        JobQueueEntry."Parameter String" := CopyStr(ParameterText, 1, MaxStrLen(JobQueueEntry."Parameter String"));
        JobQueueEntry.Insert(true);
        JobQueueEntry.SetStatus(JobQueueEntry.Status::Ready);

        UpdateDeployState(
          Setup,
          Setup."Last Deploy Status"::Scheduled,
          StrSubstNo('Deployment scheduled for %1', Format(EffectiveStart)),
          BuildWorkflowRunUrl(Setup),
          true);
    end;

    procedure RunDeployNow(var Setup: Record "Custom Approval Workflow Setup")
    begin
        ValidateDeployConfiguration(Setup);
        DispatchWorkflow(Setup);
    end;

    procedure ExecuteFromJobQueue(ParameterText: Text)
    var
        Setup: Record "Custom Approval Workflow Setup";
        SetupNo: Code[20];
    begin
        SetupNo := ParseSetupNo(ParameterText);
        if SetupNo = '' then
            Error('Missing setup number in job queue parameter string.');

        if not Setup.Get(SetupNo) then
            Error('Setup %1 not found.', SetupNo);

        ValidateDeployConfiguration(Setup);
        DispatchWorkflow(Setup);
    end;

    local procedure DispatchWorkflow(var Setup: Record "Custom Approval Workflow Setup")
    var
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        Headers: HttpHeaders;
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        Body: Text;
        RequestUrl: Text;
        WorkflowRunUrl: Text;
        ErrorTxt: Text;
    begin
        RequestUrl := BuildDispatchApiUrl(Setup);
        WorkflowRunUrl := BuildWorkflowRunUrl(Setup);

        Body := BuildDispatchBody(Setup."Deploy Branch", Setup."No.", Setup."Last Generated File Name");

        Content.WriteFrom(Body);
        Content.GetHeaders(ContentHeaders);
        if ContentHeaders.Contains('Content-Type') then
            ContentHeaders.Remove('Content-Type');
        ContentHeaders.Add('Content-Type', 'application/json');

        Request.SetRequestUri(RequestUrl);
        Request.Method := 'POST';
        Request.Content := Content;

        Request.GetHeaders(Headers);
        Headers.Add('Accept', 'application/vnd.github+json');
        Headers.Add('X-GitHub-Api-Version', '2022-11-28');
        Headers.Add('Authorization', StrSubstNo('Bearer %1', Setup."Deploy PAT Token"));

        if not Client.Send(Request, Response) then begin
            ErrorTxt := 'GitHub workflow dispatch request failed to send.';
            UpdateDeployState(Setup, Setup."Last Deploy Status"::Failed, ErrorTxt, WorkflowRunUrl, false);
            Error(ErrorTxt);
        end;

        if Response.HttpStatusCode() in [200, 201, 202, 204] then begin
            UpdateDeployState(Setup, Setup."Last Deploy Status"::Queued, 'Deployment workflow dispatched successfully.', WorkflowRunUrl, false);
            exit;
        end;

        ErrorTxt := CopyStr(StrSubstNo('Dispatch failed (%1).', Format(Response.HttpStatusCode())), 1, 250);
        UpdateDeployState(Setup, Setup."Last Deploy Status"::Failed, ErrorTxt, WorkflowRunUrl, false);
        Error('%1 Open %2 for workflow details.', ErrorTxt, WorkflowRunUrl);
    end;

    local procedure ValidateDeployConfiguration(var Setup: Record "Custom Approval Workflow Setup")
    begin
        Setup.TestField(Setup."Deploy Repo Owner");
        Setup.TestField(Setup."Deploy Repo Name");
        Setup.TestField(Setup."Deploy Branch");
        Setup.TestField(Setup."Deploy Workflow File");
        Setup.TestField(Setup."Deploy PAT Token");
    end;

    local procedure BuildDispatchApiUrl(var Setup: Record "Custom Approval Workflow Setup"): Text
    begin
        exit(StrSubstNo(
          'https://api.github.com/repos/%1/%2/actions/workflows/%3/dispatches',
          Setup."Deploy Repo Owner",
          Setup."Deploy Repo Name",
          Setup."Deploy Workflow File"));
    end;

    local procedure BuildWorkflowRunUrl(var Setup: Record "Custom Approval Workflow Setup"): Text
    begin
        exit(StrSubstNo(
          'https://github.com/%1/%2/actions/workflows/%3',
          Setup."Deploy Repo Owner",
          Setup."Deploy Repo Name",
          Setup."Deploy Workflow File"));
    end;

    local procedure BuildDispatchBody(BranchName: Text; SetupNo: Code[20]; GeneratedFileName: Text[250]): Text
    var
        Inputs: JsonObject;
        Root: JsonObject;
        BodyTxt: Text;
    begin
        Inputs.Add('setup_no', SetupNo);
        Inputs.Add('generated_file_name', GeneratedFileName);

        Root.Add('ref', BranchName);
        Root.Add('inputs', Inputs);
        Root.WriteTo(BodyTxt);
        exit(BodyTxt);
    end;

    local procedure BuildParameterText(SetupNo: Code[20]): Text
    begin
        exit(StrSubstNo('SETUP_NO=%1', SetupNo));
    end;

    local procedure ParseSetupNo(ParameterText: Text): Code[20]
    begin
        if CopyStr(ParameterText, 1, 9) <> 'SETUP_NO=' then
            exit('');

        exit(CopyStr(ParameterText, 10, 20));
    end;

    local procedure UpdateDeployState(var Setup: Record "Custom Approval Workflow Setup"; NewStatus: Option None,Scheduled,Queued,Success,Failed; Msg: Text[250]; RunUrl: Text; UpdateScheduledAt: Boolean)
    begin
        if not Setup.Get(Setup."No.") then
            exit;

        Setup."Last Deploy Status" := NewStatus;
        Setup."Last Deploy Message" := Msg;
        Setup."Last Deploy At" := CurrentDateTime();
        Setup."Last Deploy Run URL" := CopyStr(RunUrl, 1, MaxStrLen(Setup."Last Deploy Run URL"));
        if UpdateScheduledAt then
            Setup."Last Scheduled At" := CurrentDateTime();
        Setup.Modify(true);
    end;
}
