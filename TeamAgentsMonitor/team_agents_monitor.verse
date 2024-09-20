using { /Fortnite.com/Devices }
using { /Fortnite.com/UI }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/UI }
using { /Verse.org/Colors }
using { /UnrealEngine.com/Temporary/SpatialMath }

# "Team{TeamIdx+1}: All({TeamAgentsCount}) - Active({ActiveTeamAgentsCount})"
row_text_block_arr := []text_block

log_team_agents_monitor := class(log_channel):
#　スイッチがONのプレイヤーのHUDに、チームのagent数を表示する
team_agents_monitor := class(creative_device):

    @editable
    In_Switch:switch_device = switch_device{}
    @editable  #IslandSettingsのチームインデックス以下の値を設定する
    TeamIdxArr:[]int = array{0, 1, 2, 3, 4}
    <# 中央右寄せ #>
    @editable
    UI_AnchorsMin:vector2 = vector2{X := 1.0, Y := 0.5}
    @editable
    UI_AnchorsMax:vector2 = vector2{X := 1.0, Y := 0.5}
    @editable
    UI_Alignment:vector2 = vector2{X := 1.0, Y := 0.0}

    Logger:log = log{Channel:=log_team_agents_monitor}

    var MainWidgetMap:[agent]?canvas = map{}
    var AgentsCountTextBlockMap:[agent]row_text_block_arr = map{}


    OnBegin<override>()<suspends>:void=
        In_Switch.TurnedOnEvent.Subscribe(OnSwitchTurnedOn)
    

    # スイッチがONになったときの処理
    OnSwitchTurnedOn<private>(Agent:agent):void=
        spawn:
            ShowUI(Agent)
            

    # UIを表示する
    ShowUI<private>(Agent:agent)<suspends>:void=
        if:
            Player := player[Agent]
            PlayerUI := GetPlayerUI[Player]
        then:
            NewUI := CreateUI(Agent)
            PlayerUI.AddWidget(NewUI)
            if(set MainWidgetMap[Agent] = option{NewUI}){}

            UpdateUI(Agent)


    # UIを作成する
    CreateUI<private>(Agent:agent):canvas=
        TitleStackBoxSlot:stack_box_slot = stack_box_slot:
            HorizontalAlignment := horizontal_alignment.Fill
            VerticalAlignment := vertical_alignment.Center
            Widget := overlay:
                Slots := array:
                    overlay_slot:
                        HorizontalAlignment := horizontal_alignment.Fill
                        VerticalAlignment := vertical_alignment.Fill
                        Widget := color_block:
                            DefaultColor := NamedColors.CornflowerBlue
                            DefaultOpacity := 1.0

                    overlay_slot:
                        HorizontalAlignment := horizontal_alignment.Center
                        Widget := stack_box:
                            Orientation := orientation.Vertical
                            Slots := array:
                                stack_box_slot:
                                    HorizontalAlignment := horizontal_alignment.Center
                                    Widget := text_block:
                                        DefaultText := ToMessage("Team Agents Monitor.")
                                        DefaultShadowOffset := option{vector2{X := 1.0, Y := 1.0}}
                                        DefaultShadowOpacity := 1.0
                                        DefaultTextColor := NamedColors.Yellow
                                stack_box_slot:
                                    HorizontalAlignment := horizontal_alignment.Center
                                    Widget := text_block:
                                        DefaultText := ToMessage("(GetAgents[]) - (IsActive[])")
                                        DefaultShadowOffset := option{vector2{X := 1.0, Y := 1.0}}
                                        DefaultShadowOpacity := 1.0
                                        DefaultTextColor := NamedColors.WhiteSmoke

        RowStackBoxSlots:[]stack_box_slot = for(RowIdx := 0..TeamIdxArr.Length-1) do CreateARow(Agent, RowIdx)
            
        Canvas := canvas:
            Slots := array:
                canvas_slot:
                    Anchors := anchors{Minimum := UI_AnchorsMin, Maximum := UI_AnchorsMax}
                    Alignment := UI_Alignment
                    Widget := stack_box:
                        Orientation := orientation.Vertical
                        Slots := array{TitleStackBoxSlot} + RowStackBoxSlots
             

    # 1行分作成する
    CreateARow<private>(Agent:agent, RowIdx:int):stack_box_slot=
        Teams := GetPlayspace().GetTeamCollection().GetTeams()
        var TeamAgentsCount:int = 99
        var ActiveTeamAgentsCount:int = 99
        AgentsCountTextBlock:text_block = text_block:
            DefaultText := ToMessage("RowIdx={RowIdx}")
            DefaultTextColor := NamedColors.WhiteSmoke

        if(RowTextBlockArr := AgentsCountTextBlockMap[Agent]):
            if:
                NewRowTextBlockArr := RowTextBlockArr.Insert[RowTextBlockArr.Length, array{AgentsCountTextBlock}]
                set AgentsCountTextBlockMap[Agent] = NewRowTextBlockArr

            else:
                Logger.Print("CreateARow() NewRowTextBlockArr Error. RowTextBlockArr.Length={RowTextBlockArr.Length} ", ?Level:=log_level.Error)

        else:
            if(set AgentsCountTextBlockMap[Agent] = array{AgentsCountTextBlock}){}
                
        stack_box_slot:
            HorizontalAlignment := horizontal_alignment.Fill
            VerticalAlignment := vertical_alignment.Center
            Widget := overlay:
                Slots := array:
                    overlay_slot:
                        HorizontalAlignment := horizontal_alignment.Fill
                        VerticalAlignment := vertical_alignment.Fill
                        Widget := color_block:
                            DefaultColor := 
                                if(Mod[RowIdx, 2] = 0):
                                    NamedColors.DarkGreen
                                else:
                                    NamedColors.DarkGoldenrod
                            DefaultOpacity := 0.5
    
                    overlay_slot:
                        HorizontalAlignment := horizontal_alignment.Left
                        Widget := AgentsCountTextBlock
        

    # スイッチがONの間、毎秒UIを更新する。OFFにした時にUIを削除する。
    UpdateUI<private>(Agent:agent)<suspends>:void=
        TeamCollection := GetPlayspace().GetTeamCollection()
        Teams := TeamCollection.GetTeams()

        loop:
            if(In_Switch.GetCurrentState[Agent]):
                if(RowTextBlockArr := AgentsCountTextBlockMap[Agent]):
                    for(RowIdx -> TextBlock : RowTextBlockArr):
                        TextBlock.SetText(ToMessage("RowIdx={RowIdx}"))
                        TextBlock.SetTextColor(NamedColors.WhiteSmoke)
                        TextBlock.SetTextOpacity(1.0)
                 
                        var TeamAgentsCount:int = 99
                        var ActiveTeamAgentsCount:int = 99
                        if(TeamIdx := TeamIdxArr[RowIdx]):
                            if(TeamAgents := TeamCollection.GetAgents[Teams[TeamIdx]]):
                                set TeamAgentsCount = TeamAgents.Length
                                ActiveTeamAgents := for(TeamAgent : TeamAgents, player[TeamAgent].IsActive[]) do TeamAgent
                                set ActiveTeamAgentsCount = ActiveTeamAgents.Length

                                TextBlock.SetText(ToMessage("Team{TeamIdx+1}: All({TeamAgentsCount}) - Active({ActiveTeamAgentsCount})"))
                                if(TeamAgentsCount <> ActiveTeamAgentsCount):
                                    TextBlock.SetTextColor(NamedColors.Red)

                                else if(TeamAgentsCount = 0, ActiveTeamAgentsCount = 0):
                                    TextBlock.SetTextOpacity(0.1)

                            else:
                                Logger.Print("UpdateUI() TeamCollection.GetAgents Error. TeamIdx={TeamIdx}", ?Level:=log_level.Error)

                        else:
                            Logger.Print("UpdateUI() TeamIdx Error. RowIdx={RowIdx} ", ?Level:=log_level.Error)

                else:
                    Logger.Print("UpdateUI() RowTextBlockArr Error. {Agent}", ?Level:=log_level.Error)
            else:
                if:
                    Player := player[Agent]
                    PlayerUI := GetPlayerUI[Player]
                    MyUI := MainWidgetMap[Agent]?
                then:
                    PlayerUI.RemoveWidget(MyUI)
                    if(set MainWidgetMap[Agent] = false){}
                    if(set AgentsCountTextBlockMap[Agent] = array{}){}
            
            Sleep(1.0)

    ToMessage<localizes>(Text:string)<transacts>:message = "{Text}"
    ToMessage<localizes>(Agent:agent)<transacts>:message = "{Agent}"
    ToString(Agent:agent):string = "{Localize(ToMessage(Agent))}"