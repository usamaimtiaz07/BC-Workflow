page 50145 "Custom Approval Workflow Steps"
{
    ApplicationArea = All;
    Caption = 'Workflow Steps';
    PageType = ListPart;
    SourceTable = "Workflow Step";
    UsageCategory = Administration;
    SourceTableView = sorting("Workflow Code", "Sequence No.");

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Workflow Code"; Rec."Workflow Code")
                {
                    ApplicationArea = All;
                }
                field("Sequence No."; Rec."Sequence No.")
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = All;
                }
                field("Function Name"; Rec."Function Name")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenWorkflowTemplates)
            {
                ApplicationArea = All;
                Caption = 'Open Workflow Templates';
                Image = WorkflowSetup;
                ToolTip = 'Open the workflow templates page for additional step configuration.';
                trigger OnAction()
                begin
                    Page.Run(Page::"Workflow Templates");
                end;
            }
        }
    }

    var
        WorkflowCodeFilter: Code[20];

    trigger OnOpenPage()
    begin
        if WorkflowCodeFilter <> '' then begin
            Rec.SetRange("Workflow Code", WorkflowCodeFilter);
            CurrPage.Update(false);
        end;
    end;

    procedure SetWorkflowCode(Code: Code[20])
    begin
        WorkflowCodeFilter := Code;
    end;
}
