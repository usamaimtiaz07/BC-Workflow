page 50114 "Code Editor Workflow AL"
{
    ApplicationArea = All;
    Caption = 'Code Editor';
    PageType = Card;
    InsertAllowed = false;
    DeleteAllowed = false;
    LinksAllowed = false;

    layout
    {
        area(Content)
        {
            group(Intro)
            {
                Caption = 'About';
                ShowCaption = true;
                InstructionalText = 'Preview shows the full generated AL when it fits in the field; very large files are truncated in the browser. Always use Download AL File for the exact blob. Build a .app in Visual Studio Code, then upload via Extension Management.';
            }
            group(Summary)
            {
                Caption = 'Generated file';
                field(FileNameDisplay; FileNameDisplay)
                {
                    ApplicationArea = All;
                    Caption = 'Suggested file name';
                    Editable = false;
                    ToolTip = 'Last generated file name from Custom Approval Workflow setup.';
                }
                field(CharCount; CharCount)
                {
                    ApplicationArea = All;
                    Caption = 'Characters in blob';
                    Editable = false;
                    ToolTip = 'Total character count including all line breaks.';
                }
            }
            group(Editor)
            {
                Caption = 'AL source preview';
                field(PreviewTxt; PreviewTxt)
                {
                    ApplicationArea = All;
                    Caption = 'AL';
                    MultiLine = true;
                    Editable = false;
                    ToolTip = 'Read-only preview of generated page extension AL. Download for the full file.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DownloadALFile)
            {
                ApplicationArea = All;
                Caption = 'Download AL File';
                Image = ExportFile;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Download the full generated AL file.';

                trigger OnAction()
                begin
                    DownloadFromBlob();
                end;
            }
            action(ResetCode)
            {
                ApplicationArea = All;
                Caption = 'Reset Code';
                Image = Restore;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Regenerate AL from the current setup.';

                trigger OnAction()
                var
                    Gen: Codeunit "AL Page Extension Generator";
                    ALTxt: Text;
                begin
                    ALTxt := Gen.GeneratePageExtension(SetupGlobal, NextPageExtObjectId);
                    Gen.SaveGeneratedToSetup(SetupGlobal, ALTxt, NextPageExtObjectId);
                    SetupGlobal.Get(SetupGlobal."No.");
                    LoadPreview();
                    CurrPage.Update(false);
                end;
            }
            action(AutoDeploySetup)
            {
                ApplicationArea = All;
                Caption = 'AutoDeploy Setup';
                Image = Setup;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Open deployment scheduler (configure Admin Center API keys outside BC).';

                trigger OnAction()
                var
                    Mgt: Codeunit "Custom Approval Workflow Mgt.";
                begin
                    Mgt.OpenAutoDeploy(SetupGlobal);
                end;
            }
            action(ScheduleDeployment)
            {
                ApplicationArea = All;
                Caption = 'Schedule Deployment';
                Image = DateRange;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Open Auto Deploy Scheduler (same as AutoDeploy Setup).';

                trigger OnAction()
                var
                    Mgt: Codeunit "Custom Approval Workflow Mgt.";
                begin
                    Mgt.OpenAutoDeploy(SetupGlobal);
                end;
            }
            action(ClearText)
            {
                ApplicationArea = All;
                Caption = 'Clear Text';
                Image = ClearLog;
                ToolTip = 'Clear generated AL from setup.';

                trigger OnAction()
                var
                    OutS: OutStream;
                begin
                    if not SetupGlobal.Get(SetupGlobal."No.") then
                        exit;
                    SetupGlobal."Generated AL Text".CreateOutStream(OutS, TextEncoding::UTF8);
                    OutS.WriteText('');
                    SetupGlobal."Last Generated File Name" := '';
                    SetupGlobal.Modify(true);
                    LoadPreview();
                    CurrPage.Update(false);
                end;
            }
        }
    }

    var
        SetupGlobal: Record "Custom Approval Workflow Setup";
        PreviewTxt: Text;
        FileNameDisplay: Text[250];
        CharCount: Integer;
        NextPageExtObjectId: Integer;

    procedure SetSetup(var SetupIn: Record "Custom Approval Workflow Setup")
    begin
        SetupGlobal := SetupIn;
        NextPageExtObjectId := 50140;
    end;

    trigger OnOpenPage()
    begin
        LoadPreview();
    end;

    local procedure LoadPreview()
    var
        FullText: Text;
    begin
        Clear(PreviewTxt);
        Clear(FileNameDisplay);
        CharCount := 0;
        if not SetupGlobal.Get(SetupGlobal."No.") then
            exit;
        SetupGlobal.CalcFields("Generated AL Text");
        FileNameDisplay := CopyStr(SetupGlobal."Last Generated File Name", 1, MaxStrLen(FileNameDisplay));
        if FileNameDisplay = '' then
            FileNameDisplay := '(run Generate Card Page on setup)';
        if not SetupGlobal."Generated AL Text".HasValue then begin
            PreviewTxt := '// No generated AL yet. Use Generate Card Page on Custom Approval Workflow.';
            exit;
        end;
        FullText := ReadGeneratedAlTextFromSetup(SetupGlobal);
        CharCount := StrLen(FullText);
        PreviewTxt := FullText;
    end;

    local procedure ReadGeneratedAlTextFromSetup(var SetupRec: Record "Custom Approval Workflow Setup"): Text
    var
        InS: InStream;
        Line: Text;
        Tb: TextBuilder;
    begin
        SetupRec."Generated AL Text".CreateInStream(InS, TextEncoding::UTF8);
        while not InS.EOS do begin
            InS.ReadText(Line);
            Tb.AppendLine(Line);
        end;
        exit(Tb.ToText());
    end;

    local procedure DownloadFromBlob()
    var
        InS: InStream;
        FileName: Text;
    begin
        if not SetupGlobal.Get(SetupGlobal."No.") then
            exit;
        SetupGlobal.CalcFields("Generated AL Text");
        if not SetupGlobal."Generated AL Text".HasValue then begin
            Message('Nothing to download. Run Generate Card Page on the setup first.');
            exit;
        end;
        FileName := SetupGlobal."Last Generated File Name";
        if FileName = '' then
            FileName := 'PageExtension.al';
        SetupGlobal."Generated AL Text".CreateInStream(InS, TextEncoding::UTF8);
        DownloadFromStream(InS, '', '', '', FileName);
    end;
}
