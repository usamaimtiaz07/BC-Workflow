page 50115 "Auto Deploy Scheduler"
{
    ApplicationArea = All;
    Caption = 'AutoDeploy Scheduler';
    PageType = StandardDialog;
    DataCaptionExpression = '';

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
                    ToolTip = 'When on, OK runs the instant-deploy steps (see note below). Use the Deploy action for the same without closing.';
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
                InstructionalText = 'Extension Installation Status shows a new line only after you upload a .app file. Instant Deploy ON + OK opens Extension Management when the dialog closes (build the .app in Visual Studio Code first).';
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
                Enabled = InstantDeploy;
                Image = SendTo;
                ToolTip = 'Same as OK when Instant Deploy is on: opens Extension Management. Business Central cannot compile AL inside the client; you must upload a .app file.';

                trigger OnAction()
                begin
                    RunInstantDeployFlow();
                end;
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        OpenExtensionMgmtAfterClose := false;
        case CloseAction of
            CloseAction::Cancel:
                exit(true);
            CloseAction::OK, CloseAction::LookupOK:
                begin
                    if InstantDeploy then
                        OpenExtensionMgmtAfterClose := true;
                    exit(true);
                end;
            else
                exit(true);
        end;
    end;

    trigger OnClosePage()
    begin
        if not OpenExtensionMgmtAfterClose then
            exit;
        OpenExtensionMgmtAfterClose := false;
        Commit();
        RunInstantDeployFlow();
    end;

    var
        SetupGlobal: Record "Custom Approval Workflow Setup";
        ExtensionFileName: Text[250];
        InstantDeploy: Boolean;
        EarliestStart: DateTime;
        JobTimeout: Duration;
        OpenExtensionMgmtAfterClose: Boolean;

    procedure SetSetup(var SetupIn: Record "Custom Approval Workflow Setup")
    begin
        SetupGlobal := SetupIn;
        InstantDeploy := true;
        if SetupIn.Get(SetupIn."No.") then
            ExtensionFileName := CopyStr(SetupIn."Last Generated File Name", 1, MaxStrLen(ExtensionFileName));
        if ExtensionFileName = '' then
            ExtensionFileName := 'PageExtension.al';
    end;

    local procedure RunInstantDeployFlow()
    var
        ExtMgmt: Page "Extension Management";
    begin
        ExtMgmt.Run();
    end;

    local procedure RunScheduleDeployInfo()
    begin
        Message('Scheduling is not executed inside this company. Use AL-Go / GitHub Actions with the Business Central Admin Center API, or upload a .app manually when Earliest Start is due.');
    end;
}
