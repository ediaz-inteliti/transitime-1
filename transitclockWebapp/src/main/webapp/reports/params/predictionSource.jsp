<%@ page import="org.transitclock.reports.ReportsConfig" %>
<div class="param" 
<%
if(!ReportsConfig.isShowPredictionSource()) {
	out.print("style=\"display:none;\""); 
}
%>
>
	<label for="source">Prediction Source:</label> <select id="source"
		name="source"
		title="Specifies which prediction system to display data for. Selecting
     	'TransitClock' means will only show prediction data generated by TheTransitClock. 
     	If there is another prediction source then can select 'Other'. And selecting 'All'
     	displays data for all prediction sources.">
		<option value="TransitClock">TransitClock</option>
		<option value="Other">Other</option>
		<option value="">All</option>
	</select>
</div>