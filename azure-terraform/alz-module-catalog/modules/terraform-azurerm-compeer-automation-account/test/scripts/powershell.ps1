Connect-AzAccount -Identity
#
Set-AzContext -SubscriptionId 7acfa79c-1fd6-4e91-8958-1da372ff631f
#
Select-AzSubscription -SubscriptionId 7acfa79c-1fd6-4e91-8958-1da372ff631f
#
$appGateway = Get-AzApplicationGateway -Name openai2-sb4-appgtwy -ResourceGroupName openai2-ncus-sb4-rg
#
Start-AzApplicationGateway -ApplicationGateway $appGateway