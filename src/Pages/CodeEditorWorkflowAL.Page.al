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
            group(Editor)
            {
                Caption = 'Text Editor';
                field(PreviewTxt; PreviewTxt)
                {
                    ApplicationArea = All;
                    Caption = 'AL (preview, first 2048 chars)';
                    MultiLine = true;
                    Editable = false;
                    ToolTip = 'Preview of generated AL. Use Download AL File for the full blob.';
                }
                field(CharCount; CharCount)
                {
                    ApplicationArea = All;
                    Caption = 'Total characters';
                    Editable = false;
                    ToolTip = 'Full character count of the blob (all lines). Preview below shows the first 2048 characters only.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(AutoDeploySetup)
            {
                ApplicationArea = All;
                Caption = 'AutoDeploy Setup';
                Image = Setup;
                ToolTip = 'Open deployment scheduler (configure Admin Center API keys outside BC).';

                trigger OnAction()
                var
                    Mgt: Codeunit "Custom Approval Workflow Mgt.";
                begin
                    Mgt.OpenAutoDeploy(SetupGlobal);
                end;
            }
            action(DownloadALFile)
            {
                ApplicationArea = All;
                Caption = 'Download AL File';
                Image = ExportFile;
                ToolTip = 'Download the full generated AL file.';

                trigger OnAction()
                begin
                    DownloadFromBlob();
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
            action(ResetCode)
            {
                ApplicationArea = All;
                Caption = 'Reset Code';
                Image = Restore;
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
            action(ScheduleDeployment)
            {
                ApplicationArea = All;
                Caption = 'Schedule Deployment';
                Image = DateRange;
                ToolTip = 'Schedule extension deployment via Admin Center.';

                trigger OnAction()
                var
                    Mgt: Codeunit "Custom Approval Workflow Mgt.";
                begin
                    Mgt.OpenAutoDeploy(SetupGlobal);
                end;
            }
        }
    }

    var
        SetupGlobal: Record "Custom Approval Workflow Setup";
        PreviewTxt: Text[2048];
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
        CharCount := 0;
        if not SetupGlobal.Get(SetupGlobal."No.") then
            exit;
        SetupGlobal.CalcFields("Generated AL Text");
        if not SetupGlobal."Generated AL Text".HasValue then
            exit;
        FullText := ReadGeneratedAlTextFromSetup(SetupGlobal);
        CharCount := StrLen(FullText);
        PreviewTxt := CopyStr(FullText, 1, MaxStrLen(PreviewTxt));
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



