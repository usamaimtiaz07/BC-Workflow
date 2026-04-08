codeunit 50121 "AL Page Extension Generator"
{
    procedure GeneratePageExtension(var Setup: Record "Custom Approval Workflow Setup"; PageExtensionObjectId: Integer): Text
    var
        Tb: TextBuilder;
        SafeName: Text;
    begin
        if Setup."Card Page ID" = 0 then
            Error('Card Page ID must be set.');

        SafeName := SanitizeObjectName(Setup."Card Page Name");
        if SafeName = '' then
            SafeName := 'PageExt' + Format(Setup."Card Page ID");

        if Setup."Table No." = Database::"Approval Testing" then
            AppendFullApprovalTestingCardExtension(Tb, SafeName, Setup."Card Page ID", PageExtensionObjectId)
        else
            AppendMinimalApprovalStub(Tb, SafeName, Setup."Card Page ID", PageExtensionObjectId);

        exit(Tb.ToText());
    end;

    local procedure AppendFullApprovalTestingCardExtension(var Tb: TextBuilder; SafeName: Text; CardPageId: Integer; PageExtensionObjectId: Integer)
    var
        ObjName: Text[120];
    begin
        ObjName := CopyStr(SafeName + ' Approvals', 1, MaxStrLen(ObjName));
        Tb.AppendLine('pageextension ' + Format(PageExtensionObjectId) + ' "' + ObjName + '" extends ' + Format(CardPageId));
        Tb.AppendLine('{');
        Tb.AppendLine('    actions');
        Tb.AppendLine('    {');
        Tb.AppendLine('        addlast(Processing)');
        Tb.AppendLine('        {');
        Tb.AppendLine('            group(RequestApproval)');
        Tb.AppendLine('            {');
        Tb.AppendLine('                Caption = ''Request Approval'';');
        Tb.AppendLine('                action(SendApprovalRequest)');
        Tb.AppendLine('                {');
        Tb.AppendLine('                    ApplicationArea = All;');
        Tb.AppendLine('                    Caption = ''Send Approval Request'';');
        Tb.AppendLine('                    Enabled = Rec.Status = Rec.Status::Open;');
        Tb.AppendLine('                    Image = SendApprovalRequest;');
        Tb.AppendLine('                    ToolTip = ''Send an approval request for this record.'';');
        Tb.AppendLine('');
        Tb.AppendLine('                    trigger OnAction()');
        Tb.AppendLine('                    begin');
        Tb.AppendLine('                        WfMgt.SendApprovalRequest(Rec);');
        Tb.AppendLine('                    end;');
        Tb.AppendLine('                }');
        Tb.AppendLine('                action(CancelApprovalRequest)');
        Tb.AppendLine('                {');
        Tb.AppendLine('                    ApplicationArea = All;');
        Tb.AppendLine('                    Caption = ''Cancel Approval Request'';');
        Tb.AppendLine('                    Enabled = Rec.Status = Rec.Status::Pending;');
        Tb.AppendLine('                    Image = Cancel;');
        Tb.AppendLine('                    ToolTip = ''Cancel the approval request.'';');
        Tb.AppendLine('');
        Tb.AppendLine('                    trigger OnAction()');
        Tb.AppendLine('                    begin');
        Tb.AppendLine('                        WfMgt.CancelApprovalRequest(Rec);');
        Tb.AppendLine('                    end;');
        Tb.AppendLine('                }');
        Tb.AppendLine('            }');
        Tb.AppendLine('            group(Approval)');
        Tb.AppendLine('            {');
        Tb.AppendLine('                Caption = ''Approve'';');
        Tb.AppendLine('                action(Approve)');
        Tb.AppendLine('                {');
        Tb.AppendLine('                    ApplicationArea = All;');
        Tb.AppendLine('                    Caption = ''Approve'';');
        Tb.AppendLine('                    Image = Approve;');
        Tb.AppendLine('                    ToolTip = ''Approve the pending approval request.'';');
        Tb.AppendLine('                    Visible = OpenApprovalEntriesExistForCurrUser;');
        Tb.AppendLine('');
        Tb.AppendLine('                    trigger OnAction()');
        Tb.AppendLine('                    begin');
        Tb.AppendLine('                        WfMgt.ApproveRecord(Rec);');
        Tb.AppendLine('                    end;');
        Tb.AppendLine('                }');
        Tb.AppendLine('                action(Reject)');
        Tb.AppendLine('                {');
        Tb.AppendLine('                    ApplicationArea = All;');
        Tb.AppendLine('                    Caption = ''Reject'';');
        Tb.AppendLine('                    Image = Cancel;');
        Tb.AppendLine('                    ToolTip = ''Reject the pending approval request.'';');
        Tb.AppendLine('                    Visible = OpenApprovalEntriesExistForCurrUser;');
        Tb.AppendLine('');
        Tb.AppendLine('                    trigger OnAction()');
        Tb.AppendLine('                    begin');
        Tb.AppendLine('                        WfMgt.RejectRecord(Rec);');
        Tb.AppendLine('                    end;');
        Tb.AppendLine('                }');
        Tb.AppendLine('            }');
        Tb.AppendLine('        }');
        Tb.AppendLine('    }');
        Tb.AppendLine('');
        Tb.AppendLine('    var');
        Tb.AppendLine('        OpenApprovalEntriesExistForCurrUser: Boolean;');
        Tb.AppendLine('        WfMgt: Codeunit "Custom Approval Workflow Mgt.";');
        Tb.AppendLine('');
        Tb.AppendLine('    trigger OnAfterGetCurrRecord()');
        Tb.AppendLine('    begin');
        Tb.AppendLine('        OpenApprovalEntriesExistForCurrUser :=');
        Tb.AppendLine('            WfMgt.HasOpenApprovalEntriesForCurrentUser(Rec.RecordId);');
        Tb.AppendLine('    end;');
        Tb.AppendLine('}');
    end;

    local procedure AppendMinimalApprovalStub(var Tb: TextBuilder; SafeName: Text; CardPageId: Integer; PageExtensionObjectId: Integer)
    begin
        Tb.AppendLine('// Full Request Approval / Approve actions with Rec.Status and WfMgt are generated when Table No. = Approval Testing (50101).');
        Tb.AppendLine('pageextension ' + Format(PageExtensionObjectId) + ' "' + SafeName + '" extends ' + Format(CardPageId));
        Tb.AppendLine('{');
        Tb.AppendLine('    actions');
        Tb.AppendLine('    {');
        Tb.AppendLine('        addlast(Processing)');
        Tb.AppendLine('        {');
        Tb.AppendLine('            group(Approval)');
        Tb.AppendLine('            {');
        Tb.AppendLine('                Caption = ''Approval'';');
        Tb.AppendLine('                action(Approve)');
        Tb.AppendLine('                {');
        Tb.AppendLine('                    ApplicationArea = All;');
        Tb.AppendLine('                    Caption = ''Approve'';');
        Tb.AppendLine('                    Image = Approve;');
        Tb.AppendLine('                    ToolTip = ''Approve the requested changes.'';');
        Tb.AppendLine('                    Visible = OpenApprovalEntriesExistForCurrUser;');
        Tb.AppendLine('                }');
        Tb.AppendLine('            }');
        Tb.AppendLine('        }');
        Tb.AppendLine('    }');
        Tb.AppendLine('');
        Tb.AppendLine('    var');
        Tb.AppendLine('        OpenApprovalEntriesExistForCurrUser: Boolean;');
        Tb.AppendLine('        WfMgt: Codeunit "Custom Approval Workflow Mgt.";');
        Tb.AppendLine('');
        Tb.AppendLine('    trigger OnAfterGetCurrRecord()');
        Tb.AppendLine('    begin');
        Tb.AppendLine('        OpenApprovalEntriesExistForCurrUser := WfMgt.HasOpenApprovalEntriesForCurrentUser(Rec.RecordId);');
        Tb.AppendLine('    end;');
        Tb.AppendLine('}');
    end;

    procedure SaveGeneratedToSetup(var Setup: Record "Custom Approval Workflow Setup"; ALText: Text; PageExtensionObjectId: Integer)
    var
        OutS: OutStream;
        GenLine: Record "Custom Approval Wf Gen Line";
        FileName: Text;
        NextLine: Integer;
    begin
        Setup."Generated AL Text".CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(ALText);
        FileName := StrSubstNo('PageExt%1.al', PageExtensionObjectId);
        Setup."Last Generated File Name" := CopyStr(FileName, 1, MaxStrLen(Setup."Last Generated File Name"));
        Setup.Modify(true);

        GenLine.SetRange("Setup No.", Setup."No.");
        if GenLine.FindLast() then
            NextLine := GenLine."Line No." + 10000
        else
            NextLine := 10000;
        GenLine.Init();
        GenLine."Setup No." := Setup."No.";
        GenLine."Line No." := NextLine;
        GenLine.Name := CopyStr('PageExt' + Format(PageExtensionObjectId), 1, MaxStrLen(GenLine.Name));
        GenLine."File Extension" := '.al';
        GenLine.Insert(true);
    end;

    local procedure SanitizeObjectName(Name: Text): Text
    var
        i: Integer;
        c: Char;
        Result: Text;
    begin
        Name := DelChr(Name, '<>', ' ');
        for i := 1 to StrLen(Name) do begin
            c := Name[i];
            if (c in ['0' .. '9', 'A' .. 'Z', 'a' .. 'z']) then
                Result += c
            else
                if c = ' ' then
                    Result += '_';
        end;
        exit(CopyStr(Result, 1, 30));
    end;
}
