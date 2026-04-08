page 50115 "Auto Deploy Scheduler"
{
    ApplicationArea = All;
    Caption = 'AutoDeploy Scheduler';
    PageType = StandardDialog;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = true;
    LinksAllowed = false;

    layout
    {
        area(Content)
        {
            group(DeployExt)
            {
                Caption = 'Deploy Extension';
                field(ExtensionFileName; ExtensionFileName)
                {
                    ApplicationArea = All;
                    Caption = 'Extension FileName';
                    Editable = false;
                    ToolTip = 'Suggested AL file name for the generated page extension.';
                }
                field(InstantDeploy; InstantDeploy)
                {
                    ApplicationArea = All;
                    Caption = 'Instant Deploy';
                    ToolTip = 'Turn on to enable Deploy. Turn off to use Schedule and the date/time fields.';
                    trigger OnValidate()
                    begin
                        CurrPage.Update(false);
                    end;
                }
            }
            group(Schedule)
            {
                Caption = 'Schedule Deployment';
                Visible = not InstantDeploy;
                field(EarliestStart; EarliestStart)
                {
                    ApplicationArea = All;
                    Caption = 'Earliest Start Date/Time';
                    ToolTip = 'Planned deployment time.';
                    Editable = not InstantDeploy;
                }
                field(JobTimeout; JobTimeout)
                {
                    ApplicationArea = All;
                    Caption = 'Job Timeout';
                    ToolTip = 'Timeout for the deployment job.';
                    Editable = not InstantDeploy;
                }
            }
            group(Note)
            {
                ShowCaption = false;
                InstructionalText = 'Deployment triggers a GitHub Actions workflow dispatch. For instant deploy use Deploy; for deferred execution use Schedule with Earliest Start Date/Time.';
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ScheduleAction)
            {
                ApplicationArea = All;
                Caption = 'Schedule';
                Image = DateRange;
                Enabled = not InstantDeploy;
                InFooterBar = true;
                ToolTip = 'Schedule a later deployment. Disabled while Instant Deploy is on.';

                trigger OnAction()
                begin
                    RunScheduleDeployInfo();
                end;
            }
            action(DeployAction)
            {
                ApplicationArea = All;
                Caption = 'Deploy';
                Image = SendTo;
                Enabled = InstantDeploy;
                InFooterBar = true;
                ToolTip = 'Dispatch deployment workflow immediately. Enabled only when Instant Deploy is on.';

                trigger OnAction()
                begin
                    RunInstantDeployFlow();
                end;
            }
            action(CancelAction)
            {
                ApplicationArea = All;
                Caption = 'Cancel';
                Image = Cancel;
                InFooterBar = true;
                ToolTip = 'Close this page.';

                trigger OnAction()
                begin
                    CurrPage.Close();
                end;
            }
        }
    }

    var
        SetupGlobal: Record "Custom Approval Workflow Setup";
        SchedulerMgt: Codeunit "WF Deploy Scheduler Mgt";
        ExtensionFileName: Text[250];
        InstantDeploy: Boolean;
        EarliestStart: DateTime;
        JobTimeout: Duration;

    procedure SetSetup(var SetupIn: Record "Custom Approval Workflow Setup")
    begin
        SetupGlobal := SetupIn;
        InstantDeploy := true;
        if SetupIn.Get(SetupIn."No.") then
            ExtensionFileName := CopyStr(SetupIn."Last Generated File Name", 1, MaxStrLen(ExtensionFileName));
        if ExtensionFileName = '' then
            ExtensionFileName := 'PageExtension.al';
        EarliestStart := CurrentDateTime();
        JobTimeout := 30 * 60 * 1000;
    end;

    local procedure RunInstantDeployFlow()
    begin
        SchedulerMgt.RunDeployNow(SetupGlobal);
        Message('Deployment workflow queued successfully. Open the run page from Custom Approval Workflow to monitor progress.');
        CurrPage.Close();
    end;

    local procedure RunScheduleDeployInfo()
    begin
        if EarliestStart = 0DT then
            Error('Earliest Start Date/Time is required.');
        SchedulerMgt.ScheduleDeploy(SetupGlobal, EarliestStart, JobTimeout);
        Message('Deployment scheduled successfully.');
        CurrPage.Close();
    end;
}
