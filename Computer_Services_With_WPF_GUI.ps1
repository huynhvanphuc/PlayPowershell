#
#
#
#
# Created By Kaido Järvemets 05.05.2011
# DepSharee.Blogspot.com
# Configuration Manager MVP
#
#
[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[xml]$XAML = @'
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Computer Services by Kaido Järvemets" Height="493" Width="651">
    <Grid>
        <Label Content="Computer:" Height="28" HorizontalAlignment="Left" Margin="12,41,0,0" Name="Label1" VerticalAlignment="Top" FontWeight="Bold" Width="81" FontSize="13" />
        <TextBox Height="23" HorizontalAlignment="Right" Margin="0,46,384,0" Name="TxtBox_Computer" VerticalAlignment="Top" Width="146" />
        <ListView Height="310" HorizontalAlignment="Left" Margin="90,94,0,0" Name="ListView1_Services" VerticalAlignment="Top" Width="491">
            <ListView.View>
                <GridView>
                    <GridViewColumn>
                        <GridViewColumn.CellTemplate>
                            <DataTemplate>
                                <CheckBox IsChecked = "{Binding IsChecked}"></CheckBox>
                            </DataTemplate>
                        </GridViewColumn.CellTemplate>
                    </GridViewColumn>
                    <GridViewColumn Header = "Name">
                        <GridViewColumn.CellTemplate>
                            <DataTemplate>
                                <Label Name = "Name" Content = "{Binding Name}"></Label>
                            </DataTemplate>
                        </GridViewColumn.CellTemplate>
                    </GridViewColumn>
                    <GridViewColumn Header = "Status">
                        <GridViewColumn.CellTemplate>
                            <DataTemplate>
                                <Label Name = "Status" Content = "{Binding Status}"></Label>
                            </DataTemplate>
                        </GridViewColumn.CellTemplate>
                    </GridViewColumn>
                    <GridViewColumn Header = "Display Name">
                        <GridViewColumn.CellTemplate>
                            <DataTemplate>
                                <Label Name = "DisplayName" Content = "{Binding DisplayName}"></Label>
                            </DataTemplate>
                        </GridViewColumn.CellTemplate>
                    </GridViewColumn>
                </GridView>
            </ListView.View>
        </ListView>
        <Button Content="Connect" Height="23" HorizontalAlignment="Left" Margin="270,46,0,0" Name="Btn_Connect" VerticalAlignment="Top" Width="75" />
        <Button Content="Restart" Height="23" HorizontalAlignment="Left" Margin="335,419,0,0" Name="Btn_Restart" VerticalAlignment="Top" Width="75" />
        <Button Content="Stop" Height="23" HorizontalAlignment="Left" Margin="416,419,0,0" Name="Btn_Stop" VerticalAlignment="Top" Width="75" />
        <Button Content="Start" Height="23" HorizontalAlignment="Left" Margin="506,419,0,0" Name="Btn_Start" VerticalAlignment="Top" Width="75" />
        <Label Height="28" HorizontalAlignment="Left" Margin="26,418,0,0" Name="Label_Messages" VerticalAlignment="Top" Width="265" />
        <Label Content="DepSharee.BlogSpot.com" HorizontalAlignment="Left" Margin="434,12,0,414" Name="Label3" Width="147" />
    </Grid>
</Window>
'@
#Read XAML
$reader=(New-Object System.Xml.XmlNodeReader $xaml) 
$Form=[Windows.Markup.XamlReader]::Load( $reader )

#Find objects
$Connect = $form.FindName('Btn_Connect')
$Restart = $form.FindName('Btn_Restart')
$Stop = $form.FindName('Btn_Stop')
$Start = $form.FindName('Btn_Start')
$ListView1_Services = $form.FindName('ListView1_Services')

$Computer = $form.FindName('TxtBox_Computer')

$Messages = $form.FindName('Label_Messages')

# Fill ListView
Function FillListView($Computer)
{

    $script:emptyarray = New-Object System.Collections.ArrayList # Empty Array
    
    $Services = Get-Service -ComputerName $Computer # Get Services


    foreach ($item in $Services)
    {
        $tmpObject = Select-Object -InputObject "" IsChecked, Name, Status, DisplayName
        $tmpObject.IsChecked = $false 
        $tmpObject.Name = $item.Name
        $tmpObject.Status = $item.Status
        $tmpObject.DisplayName = $item.DisplayName
        $script:emptyarray += $tmpObject
    }
    
    # ListView item source
    $ListView1_Services.ItemsSource = $script:emptyarray
    
}# End of FillListviewFunction

# Function Ping Computer
Function Ping-Computer($Computer)
{
    Get-WmiObject -Class Win32_PingStatus -Filter "Address = '$Computer'"
    
}# End of Function Ping-Computer

# Connect button event
$Connect.Add_Click({

    
    If((Ping-Computer -Computer $Computer.Text).StatusCode -eq 0){
    
        $Messages.Content = ""
        FillListView -Computer $Computer.Text
        }
    Else{
        $Messages.Content = "Computer is not responding to Ping"
        }

})

# Restart button event
$Restart.Add_Click({

        foreach($AddedItem in $script:emptyarray)
        {
            if($AddedItem.IsChecked)
            {
                $Service = $AddedItem.Name
                #Invoke command
                Invoke-Command -ComputerName $Computer.Text -ArgumentList $Service -ScriptBlock {param ($Service) Restart-Service $Service}
                #Sleep three seconds
                Start-Sleep 3
                #Fill again ListView
                FillListView -Computer $Computer.Text
            }
        }

})

# Stop button Event
$Stop.Add_Click({
        
        
        foreach($AddedItem in $script:emptyarray)
        {
            if($AddedItem.IsChecked)
            {
                $Service = $AddedItem.Name
                #Invoke Command
                Invoke-Command -ComputerName $Computer.Text -ArgumentList $Service -ScriptBlock {param ($Service) Stop-Service $Service -force}
                #Sleep three seconds
                Start-Sleep 3
                #Fill again ListView
                FillListView -Computer $Computer.Text
            }
        }

})

# Start button event
$Start.Add_Click({

      foreach($AddedItem in $script:emptyarray)
        {
            if($AddedItem.IsChecked)
            {
                $Service = $AddedItem.Name 
                #Invoke command
                Invoke-Command -ComputerName $Computer.Text -ArgumentList $Service -ScriptBlock {param ($Service) Start-Service $Service}
                #Sleep three seconds
                Start-Sleep 3
                #Fill listview again
                FillListView -Computer $Computer.Text 
            }
        }

})

#Show Form
$Form.ShowDialog() | out-null