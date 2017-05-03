<%@ page language="java" pageEncoding="utf-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<body>
	<div id='model_panel' style="width:100%;">
	</div>
	<div id="model_bottom" style="width:99%;margin-top:10px;">
		<div id='model_con' style='font-size: initial;margin-bottom: 30px;margin-top:10px;'>

		</div>
		
		
		<!-- 具体报表展现区域。根据配置迭代显示对应的图表或图或表 -->
		<div id="model_reports" style="width:99%">
		</div>
	</div>
	
</body>

<script type="text/javascript">
// 全局变量
var conData = [];
var myCharts = [];
var chartList = [];
var tableList = [];
var publicList = [];
var sqlList = [];
/* colModel */
var ecolumns = [];
/* colName */
var ccolumns = [];
var toolCColumns = [];
var toolEColumns = [];
/* 汇总列 */
var toolGathers = [];
/* 二级表头 */
var groupHeaders = [];
var groupFlags = [];
var reportTitles = [];
var loadTitles = [];
var formatColss = [];
var effect = [ 'spin', 'bar', 'ring', 'whirling', 'dynamicLine', 'bubble' ];
var modelElements = [];
var modelName = "";
var modelBgName = "";
var modelVO = null;
var sendFlag = false;
var modelList = [];
var titleList = [];
var contentList = [];
var mNameList = [];
var receiveAdd = "";
var selfConList = [];
var haveQuery = false;
$(function() {
	var tempStr = file.substring(file.indexOf("?") + 1, file.length);
	
	if (tempStr.indexOf("reportFlag") != -1) {
		flagStr = tempStr.split("=");
	}
	modelName = flagStr[1];
	initModel(1);
});
function showTableDiv(n) {
	var showAttr = $("#showTable"+n).attr("showAttr");
	if (showAttr=='N') {
		$("#tableDiv"+n).show();
		$("#showTable"+n).attr("showAttr","Y")
		$("#showTable"+n).text("收起");
	} else {
		$("#tableDiv"+n).hide();
		$("#showTable"+n).attr("showAttr","N")
		$("#showTable"+n).text("数据明细");
	}
}
// 界面初始化
function initModel(col) {
	//conData = [];
	myCharts = [];
	chartList = [];
	tableList = [];
	publicList = [];
	sqlList = [];
	/* colModel */
	ecolumns = [];
	/* colName */
	ccolumns = [];
	toolCColumns = [];
	toolEColumns = [];
	/* 汇总列 */
	toolGathers = [];
	/* 二级表头 */
	groupHeaders = [];
	groupFlags = [];
	reportTitles = [];
	loadTitles = [];
	formatColss = [];
	modelElements = [];
	modelBgName = null;
	modelVO = null;
	sendFlag = false;
	titleList = [];
	contentList = [];
	mNameList = [];
	receiveAdd=null;
	selfConList = [];
	// tpl/tool/modelSend.jsp?modelId=1
	/* 根据URL后面的报表标志从数据库中找到存储的public，condition，chart信息 */
	$.ajax({
		url: "reportModel/queryModelDetail",
		type: "POST",
		cache: false,
		data: {
			modelName: modelName
		},
		dataType: "json",
		success: function(data) {
			if (data.code == 0) {
				$("#model_reports").html("");
				var dt = eval('(' + data.data + ')');
				modelVO = dt;
				modelName = dt.modelName;
				modelBgName = dt.modelTitle;
				receiveAdd= dt.receiveAdd;
				// 条件拼凑
				var conList = dt.reportConditionList;
				if (conData.length == 0) {
					$("#model_con").html("");
					for (i in conList) {
						var conValueArry = new Array();
						/* 若select和checkBox是sql则先查询该sql的结果 */
						if (conList[i].conOption == "select" || conList[i].conOption == "checkbox") {
							var conValue = conList[i].conMuti;
							if (conValue.indexOf("select") != -1) {
								$.ajax({
									type: "post",
									url: "report/getConValue",
									dataType: 'json',
									async: false,
									data: {
										dataBaseSource : conList[i].dataBaseSource,
										selectSql : conValue
									},
									success: function(data) {
										if (data.code == 0) {
											conValue = data.data;
										} else {
											jAlert(data.msg, '警告');
										}
									}
								});
							}
							conValue = replaceDot(conValue);
							conValueArry = conValue.split(',');
						}

						/* 显示页面条件 */
						if (conList[i].conOption == "input") {
							$("#model_con").append(conList[i].conName + "<span style='margin-left: 10px;'></span><input type='text' class='input' name='" + conList[i].conWhere + "'/><span style='margin-left: 10px;'></span>");
							if (conList[i].conType == "日期") {
								datePickInit($("input[name='" + conList[i].conWhere + "']"), conList[i].conName);
							}
							
							var obj = new Object();
							obj.name = conList[i].conWhere;
							obj.value = $("input[name='" + conList[i].conWhere + "']").val();
							obj.option = conList[i].conType;
							obj.conName = conList[i].conName;
							obj.type = "input";
							obj.conDefaultValue = conList[i].conDefaultValue;
							conData.push(obj);
						} else if (conList[i].conOption == "select") {
							if (conList[i].conType == "模糊查询") {
								$("#model_con").append(conList[i].conName + "<span style='margin-left: 10px;'/><div class='dynamicDiv'><span style='margin-left: 10px;'></span><input type='text' style='width:200px;' name='input"+conList[i].conWhere+"'><ul class='dynamicUl' name='ul"+conList[i].conWhere+"'></ul></div>");
					        	var dynamicName = conValueArry;
					        	var conWhere = conList[i].conWhere;
					        	$("input[name='input" + conWhere + "']").attr("placeholder",dynamicName[0]);
					        	$("input[name='input" + conWhere + "']").focus(function(){
				        		if ($("input[name='input" + conWhere + "']").val() == "") {
				        			for(var i=0;i<dynamicName.length;i++){
				        				if (dynamicName[i].length >= 12) {
				        					$("ul[name='ul" + conWhere + "']").append("<li><a href=\"#\" style=\"color:black\" onclick=\"inDynamicName('"+dynamicName[i]+"','"+ conWhere +"')\">"+dynamicName[i].substring(0,10)+"...</a></li>");	
				        				} else
				        					$("ul[name='ul" + conWhere + "']").append("<li><a href=\"#\" style=\"color:black\" onclick=\"inDynamicName('"+dynamicName[i]+"','"+ conWhere +"')\">"+dynamicName[i]+"</a></li>");
				        			}
				        		}
				        		$("ul[name='ul" + conWhere + "']").show();
					        	});
					        	
					        	$("input[name='input" + conWhere + "']").bind('input propertychange', function() {
					        		var getDynamicName = $("input[name='input" + conWhere + "']").val(); 
					        		$("ul[name='ul" + conWhere + "']").html("");
					        		for(var i=0;i<dynamicName.length;i++){
					        			if (dynamicName[i] != null && dynamicName[i].indexOf(getDynamicName) > -1) {
					        				if (dynamicName[i].length >= 12) {
					        					$("ul[name='ul" + conWhere + "']").append("<li><a href=\"#\" style=\"color:black\" onclick=\"inDynamicName('"+dynamicName[i]+"','"+ conWhere +"')\">"+dynamicName[i].substring(0,10)+"...</a></li>");
					        				} else 
					        					$("ul[name='ul" + conWhere + "']").append("<li><a href=\"#\" style=\"color:black\" onclick=\"inDynamicName('"+dynamicName[i]+"','"+ conWhere +"')\">"+dynamicName[i]+"</a></li>");
					        			}
					        		}
					        	});
					        	var obj = new Object();
								obj.name = conList[i].conWhere;
								obj.option = "模糊查询";
								obj.conName = conList[i].conName;
								obj.value = $("input[name='" + conList[i].conWhere + "']").val();
								obj.type = "select";
								conData.push(obj);
							} else {
								$("#model_con").append(
										conList[i].conName + "<span style='margin-left: 10px;'></span><select id='conValueSelect" + i + "' name='" + conList[i].conWhere + "'></select>");
										$.each(conValueArry, function(n, value) {
											$("#conValueSelect" + i).append("<option value='" + value + "'>" + value + "</option>");
										});
										var obj = new Object();
										obj.name = conList[i].conWhere;
										obj.option = "文本";
										obj.conName = conList[i].conName;
										obj.value = $("select[name='" + conList[i].conWhere + "'] :selected").val();
										obj.type = "select";
										conData.push(obj);
							}
						} else if (conList[i].conOption == "checkbox") {
							$("#model_con").append(conList[i].conName);
							$.each(conValueArry, function(n, value) {
								$("#model_con").append("<span style='margin-left: 10px;'></span><input type='checkbox' name='" + conList[i].conWhere + "' value='" + value + "'>" + value + "</input>");
							});
							var chk_value_show = "";
							$("input[name='" + conList[i].conWhere + "']:checked").each(function() {
								chk_value_show = chk_value_show + $(this).val() + ",";
							});
							var obj = new Object();
							obj.name = conList[i].conWhere;
							obj.conName = conList[i].conName;
							obj.option = "文本";
							obj.value = chk_value_show;
							obj.type = "checkbox";
							obj.checkboxName = conList[i].conName;
							conData.push(obj);
						}
					}
					$("#model_con").append("<br/><br/><input type='button' class='constr borders' value='查看' onclick='showReports()'/>");
					if (col == 2) {
						$("#model_con").append("<input type='button' id='colStyle' class='constr borders' style='margin-left:10px;' colAttr='1' value='单排展示' onclick='initModel(1);'/>");
					} else {
						$("#model_con").append("<input type='button' id='colStyle' class='constr borders' style='margin-left:10px;' colAttr='2' value='双排展示' onclick='initModel(2);'/>");
					}
					$("#model_con").append("<input type='button' class='constr borders' style='margin-left:10px;' value='全部展开数据' onclick='expand()'/>");
					$("#model_con").append("<input type='button' class='constr borders' style='margin-left:10px;' value='全部收起数据' onclick='packUp()'/>");
				} else {
					if (col == 2) {
						$("#colStyle").attr("colAttr", "1");
						$("#colStyle").attr("onClick", "initModel(1)");
						$("#colStyle").attr("value", "单排展示");
					} else {
						$("#colStyle").attr("colAttr", "2");
						$("#colStyle").attr("onClick", "initModel(2)");
						$("#colStyle").attr("value", "双排展示");
					}
				}
				
				
				// 表格展示
				modelElements = dt.modelElementsList;
				// 初始化页面和全局变量
				if (col == 2) {
					$("#model_reports").append("<div id='model_reports1' style='float:left;width:49%;'></div><div id='model_reports2' style='float:right;width:49%;'></div>");
				}
				$.each(modelElements, function(n, modelElement) {
					chartList.push(modelElement.reportChart);
					sqlList.push(modelElement.qid);
					publicList.push(modelElement.reportPublic);
					if (col == 2) {
						if (n%2==0) {
							$("#model_reports1").append("<div id='model_report"+n+"' style='margin-top:10px;border: 1px solid #b4b4b4;'><div style='height: 41px;line-height: 43px;padding: 0 23px;background: url(css/images/backg.png) 0 -297px repeat-x;border-bottom: 1px solid #b4b4b4;'>" + modelElement.reportPublic.toolTitle + "</div></div>");
						} else {
							$("#model_reports2").append("<div id='model_report"+n+"' style='margin-top:10px;border: 1px solid #b4b4b4;'><div style='height: 41px;line-height: 43px;padding: 0 23px;background: url(css/images/backg.png) 0 -297px repeat-x;border-bottom: 1px solid #b4b4b4;'>" + modelElement.reportPublic.toolTitle + "</div></div>");
						}
					} else {
						$("#model_reports").append("<div id='model_report"+n+"' style='margin-top:20px;border: 1px solid #b4b4b4;'><div style='height: 41px;line-height: 43px;padding: 0 23px;background: url(css/images/backg.png) 0 -297px repeat-x;border-bottom: 1px solid #b4b4b4;'>" + modelElement.reportPublic.toolTitle + "</div></div>");
					}
					
					
					if (col == 2) {
						if (modelElement.chartShow && !modelElement.tableShow) {
							$("#model_report"+n).append("<div id='report_chart"+n+"' style='height: 300px; width: 99%;'></div>")
													.append("<div id='tableDiv" + n + "' class='reportTable' style='display:none;'><table id='list"+n+"'></table><div id='pager"+n+"'></div></div><div class='mod mod1 showdetails' style='border-width: 0px;'><a href='###' id='showTable" + n + "' class='expandCollapse' expand-id='totalDetails' showAttr='N' onclick='showTableDiv("+n+")'>数据明细</a></div>");
						} else if (!modelElement.chartShow && modelElement.tableShow) {
							$("#model_report"+n).append("<div id='report_chart"+n+"' style='height: 300px; width: 99%;'></div>")
													.append("<div id='tableDiv" + n + "' class='reportTable' style=''><table id='list"+n+"'></table><div id='pager"+n+"'></div></div><div class='mod mod1 showdetails' style='border-width: 0px;'><a href='###' id='showTable" + n + "' class='expandCollapse' expand-id='totalDetails' showAttr='Y' onclick='showTableDiv("+n+")'>收起</a></div>");
						} else if (modelElement.chartShow && modelElement.tableShow) {
							$("#model_report"+n).append("<div id='report_chart"+n+"' style='height: 300px; width: 99%;'></div>")
													.append("<div id='tableDiv" + n + "' class='reportTable' style=''><table id='list"+n+"'></table><div id='pager"+n+"'></div></div><div class='mod mod1 showdetails' style='border-width: 0px;'><a href='###' id='showTable" + n + "' class='expandCollapse' expand-id='totalDetails' showAttr='Y' onclick='showTableDiv("+n+")'>收起</a></div>");
						}
					} else {
						if (modelElement.chartShow && !modelElement.tableShow) {
							$("#model_report"+n).append("<div id='report_chart"+n+"' style='height: 500px; width: 95%;'></div>")
													.append("<div id='tableDiv" + n + "' class='reportTable' style='display:none;'><table id='list"+n+"'></table><div id='pager"+n+"'></div></div><div class='mod mod1 showdetails' style='border-width: 0px;'><a href='###' id='showTable" + n + "' class='expandCollapse' expand-id='totalDetails' showAttr='N' onclick='showTableDiv("+n+")'>数据明细</a></div>");
						} else if (!modelElement.chartShow && modelElement.tableShow) {
							$("#model_report"+n).append("<div id='report_chart"+n+"' style='height: 500px; width: 95%;'></div>")
													.append("<div id='tableDiv" + n + "' class='reportTable' ><table id='list"+n+"'></table><div id='pager"+n+"'></div></div><div class='mod mod1 showdetails' style='border-width: 0px;'><a href='###' id='showTable" + n + "' class='expandCollapse' expand-id='totalDetails' showAttr='Y' onclick='showTableDiv("+n+")'>收起</a></div>");
						} else if (modelElement.chartShow && modelElement.tableShow) {
							$("#model_report"+n).append("<div id='report_chart"+n+"' style='height: 500px; width: 95%;'></div>")
													.append("<div id='tableDiv" + n + "' class='reportTable' ><table id='list"+n+"'></table><div id='pager"+n+"'></div></div><div class='mod mod1 showdetails' style='border-width: 0px;'><a href='###' id='showTable" + n + "' class='expandCollapse' expand-id='totalDetails' showAttr='Y' onclick='showTableDiv("+n+")'>收起</a></div>");
						}
					}
					
					if (!modelElement.chartShow) {
						$("#report_chart" + n).hide();
					}
					
					
					
					
					
					if (modelElement.reportConditionList.length != 0) {
						for (i in modelElement.reportConditionList) {
							
							var selfCon = [];
							var rptCon = modelElement.reportConditionList[i];
							var conValueArry = new Array();
							/* 显示页面条件 */
							if (rptCon.conOption == "input") {
								var obj = new Object();
								obj.name = rptCon.conWhere;
								obj.value = rptCon.conDefaultValue;
								obj.option = rptCon.conType;
								obj.conName = rptCon.conName;
								obj.type = "input";
								obj.conDefaultValue = rptCon.conDefaultValue;
								selfCon.push(obj);
							} else if (rptCon.conOption == "select") {
								if (rptCon.conType == "模糊查询") {
						        	var obj = new Object();
									obj.name = rptCon.conWhere;
									obj.option = "模糊查询";
									obj.conName = rptCon.conName;
									obj.value = rptCon.conDefaultValue;
									obj.type = "select";
									selfCon.push(obj);
								} else {
									var obj = new Object();
									obj.name = rptCon.conWhere;
									obj.option = "文本";
									obj.conName = rptCon.conName;
									obj.value = rptCon.conDefaultValue;
									obj.type = "select";
									selfCon.push(obj);
								}
							} else if (rptCon.conOption == "checkbox") {
								var obj = new Object();
								obj.name = rptCon.conWhere;
								obj.conName = rptCon.conName;
								obj.option = "文本";
								obj.value = rptCon.conDefaultValue;
								obj.type = "checkbox";
								obj.checkboxName = rptCon.conName;
								selfCon.push(obj);
							}
							selfConList.push(selfCon);
						}
					} else {
						selfConList.push(null);
					}
					
					
				});
				imgInit();
				
				for ( var i in conData) {
					if (conData[i].type == "input") {
						conData[i].value = $("input[name='" + conData[i].name + "']").val();
		
					} else if (conData[i].type == "select") {
						if (conData[i].option=='模糊查询') {
							if ($("input[name='input" + conData[i].name + "']").val()=="") {
								conData[i].value = $("input[name='input" + conData[i].name + "']").attr("placeholder");
							} else {
								conData[i].value = $("input[name='input" + conData[i].name + "']").val();
							}
						} else {
							conData[i].value = $("select[name='" + conData[i].name + "'] :selected").val();
						}
					} else if (conData[i].type == "checkbox") {
							var chk_value_show = "";
							$("input[name='" + conData[i].name + "']:checked").each(function() {
										chk_value_show = chk_value_show + $(this).val() + ",";
							});
			
							if (chk_value_show == "") {
								jAlert("请勾选要查询的" + conData[i].checkboxName + "！", "警告");
								return;
							}
							conData[i].value = chk_value_show;
					}
				}
				
				$.each(modelElements, function(n, modelElement) {
					$("#list"+n).jqGrid('GridUnload');//重新构造
					var ecolumn = [];
					var ccolumn = []; /* 格式化表格展示 */
					toolEColumn = modelElement.reportPublic.toolEColumn;
					toolEColumn = toolEColumn.split(","); /* 格式化colModel */
					toolEColumns.push(toolEColumn);
					$.each(toolEColumn, function(n, value) {
						var obj = new Object();
						obj.name = value;
						obj.index = value;
						ecolumn.push(obj);
					});
					
					ecolumns.push(ecolumn);
					formatCols = modelElement.reportPublic.toolFormat;
					formatColss.push(formatCols);
					toolGather = modelElement.reportPublic.toolGather;
					toolGathers.push(toolGather);
					toolCColumn = modelElement.reportPublic.toolCColumn;
					toolCColumn = toolCColumn.split(",");
					toolCColumns.push(toolCColumn);
					var ecindex = 0;
					var groupHeader = [];
					for (var i = 0; i < toolCColumn.length; i++) {
						if (toolCColumn[i].indexOf(":") != -1 && toolCColumn[i].indexOf("{") != -1 && toolCColumn[i].indexOf("}") != -1) {
							groupFlag = true; /* 拼装groupHeader */
							var obj = new Object();
							obj.titleText = toolCColumn[i].substring(0, toolCColumn[i].indexOf(":"));
							obj.numberOfColumns = toolCColumn[i].substring(toolCColumn[i].indexOf("{"), toolCColumn[i].indexOf("}")).split("|").length;
							/* 拼装colNames */
							var tmpArr = [];
							tmpArr = toolCColumn[i].substring(toolCColumn[i].indexOf("{") + 1, toolCColumn[i].indexOf("}")).split("|");
							obj.startColumnName = ecolumn[ecindex].name;
							groupHeader.push(obj);
							ccolumn = $.merge(ccolumn, tmpArr);
							ecindex = ecindex + obj.numberOfColumns;
						} else {
							ccolumn.push(toolCColumn[i]);
							ecindex++;
						}
					}
					ccolumns.push(ccolumn);
					groupHeaders.push(groupHeader);
					loadTitle = modelElement.reportPublic.toolCColumn;
					loadTitles.push(loadTitle);

					reportTitle = modelElement.reportPublic.toolTitle;
					reportTitles.push(reportTitle);
					/* 格式化的时候触发该事件，准备格式化数据 */
					var formatDatas = [];
					var toolFormat = modelElement.reportPublic.toolFormat;
					if (toolFormat != undefined && toolFormat != "") {
						toolFormat = toolFormat.split(","); /* 金额:负数,笔数:百分比, */
						for (var k = 0; k < toolFormat.length; k++) {
							if (toolFormat[k] != "") {
								var tmpFmt = toolFormat[k].split(":");
								var formatSelect = tmpFmt[0];
								var columnType = tmpFmt[1];
								var obj = new Object();
								var fmtObj = new Object();
								if (columnType == "正整数") {
									obj.name = formatSelect;
									obj.formatter = "integer";
									fmtObj.thousandsSeparator = ",";
									fmtObj.defaultValue = "0";
									obj.formatoptions = fmtObj;
								} else if (columnType == "小数") {
									obj.name = formatSelect;
									obj.formatter = "number";
									fmtObj.decimalSeparator = ".";
									fmtObj.thousandsSeparator = ",";
									fmtObj.decimalPlaces = 2;
									fmtObj.defaultValue = "0.00";
									obj.formatoptions = fmtObj;
								} else if (columnType == "负数") {
									obj.name = formatSelect;
									obj.formatter = "currency";
									fmtObj.decimalSeparator = ".";
									fmtObj.thousandsSeparator = ",";
									fmtObj.decimalPlaces = "2";
									fmtObj.prefix = "-";
									fmtObj.defaultValue = "-0.00";
									obj.formatoptions = fmtObj;
								} else if (columnType == "百分比") {
									obj.name = formatSelect;
									obj.formatter = "currency";
									fmtObj.decimalSeparator = ".";
									fmtObj.thousandsSeparator = ",";
									fmtObj.decimalPlaces = "2";
									fmtObj.defaultValue = "0.00%";
									fmtObj.suffix = "%";
									obj.formatoptions = fmtObj;
								}
								formatDatas.push(obj);
							}
						} /* 格式化表格 */
						if (formatDatas.length > 0) {
							for (var i = 0; i < formatDatas.length; i++) {
								for (var j = 0; j < ccolumn.length; j++) {
									if (formatDatas[i].name == ccolumn[j]) {
										var obj = new Object();
										obj.name = ecolumn[j].name;
										obj.index = ecolumn[j].index;
										obj.formatter = formatDatas[i].formatter;
										obj.formatoptions = formatDatas[i].formatoptions;
										ecolumn[j] = obj;
									}
								}
							}
						}
						//ecolumns.push(ecolumn);

					}
					
					
				});
				if (haveQuery) {
					showReports ();
				}
				//initJqGrid();
				// 图形展示
				//chartList = data.reportChartList == undefined ? [] : data.reportChartList;
			} else {
				jAlert("未搜索到该模板", '警告');
			}
			
		}
	});
}

// 查找模板明细
function searchModel () {
	
}


// 重新赋值公共时间条件中的值
function reloadDateValue () {
	for ( var i in conData) {
		if (conData[i].type == "input") {
			conData[i].value = $("input[name='" + conData[i].name + "']").val();

		} else if (conData[i].type == "select") {
			if (conData[i].option=='模糊查询') {
				if ($("input[name='input" + conData[i].name + "']").val()=="") {
					conData[i].value = $("input[name='input" + conData[i].name + "']").attr("placeholder");
				} else {
					conData[i].value = $("input[name='input" + conData[i].name + "']").val();
				}
			} else {
				conData[i].value = $("select[name='" + conData[i].name + "'] :selected").val();
			}
		} else if (conData[i].type == "checkbox") {
				var chk_value_show = "";
				$("input[name='" + conData[i].name + "']:checked").each(function() {
							chk_value_show = chk_value_show + $(this).val() + ",";
				});

				if (chk_value_show == "") {
					jAlert("请勾选要查询的" + conData[i].checkboxName + "！", "警告");
					return;
				}
				conData[i].value = chk_value_show;
		}
	}
}
// 根据查询的对象更新图表区域
function showReports () {
/* 	changeBG (); */
	haveQuery = true;
	$.each(myCharts, function(n, myChart) {
		myChart.showLoading({
			text : '数据查询中',
			effect : effect[3],
			textStyle : {
				fontSize : 20
			}
		});
	});
	
	reloadDateValue ();
	$.each(modelElements, function(n, modelElement) {
		$("#list"+n).jqGrid('GridUnload');//重新构造
	});
	initJqGrid();
}


/* 展现图表 */
function showChart(v) {
	if (chartList.length > 0 && modelElements[v].chartShow) {
			/*展示选中的图*/
		if (chartList[v].chartType == 'bar') {
			var columnVsLegend = chartList[v].dataVsLe;
			var columnVsX = chartList[v].dataVsX;
			var option = chartList[v].chartOption;
			if (option.length > 0) {
				if (!isJson(option)) {
					option = eval('(' + option + ')');
				}
			}
			/* e.g result:结果,sumAmt:金额,sumcnt:笔数 */
			var columnVsLegends = columnVsLegend.split(",");
			/* option.series赋值  */
			$.each(columnVsLegends, function(n, value) {
				var strs = value.split(":");
				$.each(option.series, function(n, value) {
					if (value.name == strs[1]) {
						/* 正常显示 */
						
						var tempArr = jQuery("#list"+v).jqGrid('getCol', strs[0]).reverse();
						for (var j = 0; j < tempArr.length; j++) {
							tempArr[j] = Number(tempArr[j]);
						}
						value.data = tempArr;
					}
				});
			});
			
			/* tx_date:日期   tx_date:日期|tran_type */
			var xdatas = columnVsX.split(":");
			/* 正常显示 */
			if (columnVsX.indexOf("|") == -1) {
				if (option.xAxis.length == 1) {
					option.xAxis[0].data = jQuery("#list" + v).jqGrid(
							'getCol', xdatas[0]).reverse();
				} else if (option.xAxis.length == 2) {
					option.xAxis[0].data = jQuery("#list" + v).jqGrid(
							'getCol', xdatas[0]).reverse();
					option.xAxis[1].data = jQuery("#list" + v).jqGrid(
							'getCol', xdatas[0]).reverse();
				}
			}
			myCharts[v].setOption(option, true);
		} else if (chartList[v].chartType == 'pie') {
			var columnVsLegend = chartList[v].dataVsLe;
			var columnVsX = chartList[v].dataVsX;
			var option = chartList[v].chartOption;
			var showRowNum = chartList[v].showRowNum;
			if (option.length > 0) {
				if (!isJson(option)) {
					option = eval('(' + option + ')');
				}
			}
			var pieKey = jQuery("#list" + v).jqGrid('getCol', columnVsX);
			var pieValue = jQuery("#list" + v).jqGrid('getCol', columnVsLegend);
			option.legend.data = pieKey;
			var pieSeriesData = [];
			var pieSeriesData = [];
			var otherSumName = "其他";
			var otherSumValue = 0;
			var otherShow = false;
			for (var x in pieKey) {
				if (x < showRowNum * 1) {
					var obj = new Object();
					obj.name = pieKey[x];
					obj.value = pieValue[x];
					pieSeriesData.push(obj);
				} else {
					otherShow = true;
					otherSumValue += pieValue[x] * 1;
				}
			}
			if (pieKey.length > showRowNum * 1) {
				option.legend.data.push('其他');
			}
			if (otherShow) {
				pieSeriesData.push({name: otherSumName, value: otherSumValue});
			}
			option.series[0].data = pieSeriesData;
			myCharts[v].setOption(option, true);
		}
	}
}
// 其他函数
function datePickInit (conNode, conName) {
	var time = $('.currentItem a').attr('time');
	conNode.removeClass("hasDatepicker");
	if (time == "日") {
		if (conName.indexOf("开始") != -1 || conName.indexOf("begin") != -1) {
			dayPickerBeginInit(conNode);
		} else if (conName.indexOf("结束") != -1 || conName.indexOf("end") != -1) {
			dayPickerEndInit(conNode);
		}
	} else if (time == "周") {
		if (conName.indexOf("开始") != -1 || conName.indexOf("begin") != -1) {
			weekPickerBeginInit(conNode);
		} else if (conName.indexOf("结束") != -1 || conName.indexOf("end") != -1) {
			weekPickerEndInit(conNode);
		}
	} else if (time == "月") {
		monthPickerInit(conNode);
	}
}

/* echarts图表初始化 */
function imgInit() {
	require.config({
				paths : {
					'echarts' : '${pageContext.request.contextPath}/js/echarts', //echarts.js的路径
					'echarts/chart/line' : '${pageContext.request.contextPath}/js/echarts', //echarts.js的路径
					'echarts/chart/bar' : '${pageContext.request.contextPath}/js/echarts',
					'echarts/chart/pie' : '${pageContext.request.contextPath}/js/echarts'
				}
			});
	require([ 'echarts', 'echarts/chart/line', 'echarts/chart/bar', 'echarts/chart/pie' ],
			DrawEChart);
	//渲染ECharts图表

}

/* 图表回调函数 */
function DrawEChart(ec) {
	/* 图表渲染的容器对象 */
	$.each(chartList, function(n, chart) {
		var chartContainer = document.getElementById("report_chart" + n);
		/* 加载图表 */
		myCharts.push(ec.init(chartContainer));
	});
}
/* 查询表格数据 */
function initJqGrid() {
	$.each(toolCColumns, function(n, toolCColumn) {
		var sendConData = [];
		if (selfConList[n] != null) {
			for (var k=0; k<conData.length;k++) {
				// 周报和月报的时间格式转换
				if (modelElements[n].timeDimension == 'd') {
					if ((conData[k].conName.indexOf('开始') != -1 && conData[k].name.indexOf("begin") != -1)
							||(conData[k].conName.indexOf('结束') != -1 && conData[k].name.indexOf("end") != -1)	){
						conData[k].value = $("input[name='" + conData[k].name + "']").val();
						}
				} else if (modelElements[n].timeDimension == 'w') {
					if (conData[k].conName.indexOf('开始') != -1 && conData[k].name.indexOf("begin") != -1) {
						var nowDate = new Date(conData[k].value);
						nowDate = new Date(nowDate.getFullYear(), nowDate.getMonth(), nowDate.getDate() - nowDate.getDay());
						conData[k].value = nowDate.getFullYear() + "-" + ((nowDate.getMonth()+1)<10?("0"+(nowDate.getMonth()+1)):(nowDate.getMonth()+1)) + "-" + (nowDate.getDate()<10?"0"+nowDate.getDate():nowDate.getDate());
					} else if (conData[k].conName.indexOf('结束') != -1 && conData[k].name.indexOf("end") != -1) {
						var nowDate = new Date(conData[k].value);
						nowDate = new Date(nowDate.getFullYear(), nowDate.getMonth(), nowDate.getDate() - nowDate.getDay() + 6);
						conData[k].value = nowDate.getFullYear() + "-" + ((nowDate.getMonth()+1)<10?("0"+(nowDate.getMonth()+1)):(nowDate.getMonth()+1)) + "-" + (nowDate.getDate()<10?"0"+nowDate.getDate():nowDate.getDate());
					}
				} else if (modelElements[n].timeDimension == 'm') {
					nowDate = new Date(conData[k].value);
					conData[k].value = nowDate.getFullYear() + "-" + ((nowDate.getMonth()+1)<10?("0"+(nowDate.getMonth()+1)):(nowDate.getMonth()+1));
				}
				
				if (modelElements[n].beginTimeOnly == "Y" && conData[k].conName.indexOf('结束') != -1 && conData[k].name.indexOf("end") != -1) {
					continue;
				}
				if (modelElements[n].endTimeOnly == "Y" && conData[k].conName.indexOf('开始') != -1 && conData[k].name.indexOf("begin") != -1) {
					continue;
				}
				sendConData.push(conData[k]);
			}
			for (var l=0; l<selfConList[n].length;l++) {
				sendConData.push(selfConList[n][l]);
			}
		} else {
			for (var k=0; k<conData.length;k++) {
				// 周报和月报的时间格式转换
				if (modelElements[n].timeDimension == 'd') {
					if ((conData[k].conName.indexOf('开始') != -1 && conData[k].name.indexOf("begin") != -1)
							||(conData[k].conName.indexOf('结束') != -1 && conData[k].name.indexOf("end") != -1)	){
						conData[k].value = $("input[name='" + conData[k].name + "']").val();
						}
				} else if (modelElements[n].timeDimension == 'w') {
					if (conData[k].conName.indexOf('开始') != -1 && conData[k].name.indexOf("begin") != -1) {
						var nowDate = new Date(conData[k].value);
						nowDate = new Date(nowDate.getFullYear(), nowDate.getMonth(), nowDate.getDate() - nowDate.getDay());
						conData[k].value = nowDate.getFullYear() + "-" + ((nowDate.getMonth()+1)<10?("0"+(nowDate.getMonth()+1)):(nowDate.getMonth()+1)) + "-" + (nowDate.getDate()<10?"0"+nowDate.getDate():nowDate.getDate());
					} else if (conData[k].conName.indexOf('结束') != -1 && conData[k].name.indexOf("end") != -1) {
						var nowDate = new Date(conData[k].value);
						nowDate = new Date(nowDate.getFullYear(), nowDate.getMonth(), nowDate.getDate() - nowDate.getDay() + 6);
						conData[k].value = nowDate.getFullYear() + "-" + ((nowDate.getMonth()+1)<10?("0"+(nowDate.getMonth()+1)):(nowDate.getMonth()+1)) + "-" + (nowDate.getDate()<10?"0"+nowDate.getDate():nowDate.getDate());
					}
				} else if (modelElements[n].timeDimension == 'm') {
					nowDate = new Date(conData[k].value);
					conData[k].value = nowDate.getFullYear() + "-" + ((nowDate.getMonth()+1)<10?("0"+(nowDate.getMonth()+1)):(nowDate.getMonth()+1));
				}
				
				if (modelElements[n].beginTimeOnly == "Y" && conData[k].conName.indexOf('结束') != -1 && conData[k].name.indexOf("end") != -1) {
					continue;
				}
				if (modelElements[n].endTimeOnly == "Y" && conData[k].conName.indexOf('开始') != -1 && conData[k].name.indexOf("begin") != -1) {
					continue;
				}
				sendConData.push(conData[k]);
			}
		}
		
		var gridWidth = $("#model_report"+n).width();
		var gridHeight = 200;
		var col = $("#colStyle").attr('colattr');
		if (col == 1) {
			gridWidth = $("#model_report"+n).width() * 0.98;
			gridHeight = 226;
		}
		
		jQuery("#list"+n).jqGrid(
					{
						url : 'report/reportShowQueryData',
						datatype : "json",
						mtype : 'post',
						colNames : ccolumns[n],
						colModel : ecolumns[n],
						height : gridHeight,
						width :  gridWidth,
						ajaxGridOptions:{timeout : 5 * 60 * 1000},
						postData : {
							qid : sqlList[n],
							condition : JSON.stringify(sendConData)
						},
						rowNum : 10,
						rowList : [10, 20, 50, 1000],
						pager : '#pager'+n,
						sortname : '',
						viewrecords : true,
						sortorder : '',
						//caption : reportTitles[n],
						footerrow : true,
						userDataOnFooter : true,
						altRows : true,
						loadError : function(xhr, status, error) {
							$("#gbox_list"+n).css("border-radius","0");
							myCharts[n].hideLoading();
							myCharts[n].clear();
							jAlert("该报表出现问题,已记录,我们会尽快修复", "提示");
						},
						loadComplete : function() {
							$("#gbox_list"+n).css("border-radius","0");
							myCharts[n].hideLoading();
							var re_records = $("#list"+n).getGridParam('records');
							if (re_records != null && re_records != "") {
								if (chartList.length > 0) {
									showChart(n);
								}
								/* 汇总功能 */
								if (toolGathers[n] != null && toolGathers[n] != "") {
									var gathers = toolGathers[n].split(",");
									var gatheJson = "";
									if (gathers.length > 0) {
										for (var j = 0; j < gathers.length; j++) {
											for (var k = 0; k < ccolumns[n].length; k++) {
												if (ccolumns[n][k] == gathers[j]) {
													var gatherJsonKey = ecolumns[n][k].name;
													var dataList = jQuery("#list"+n)
															.jqGrid('getCol',
																	gatherJsonKey);
													gatheJson = gatheJson
															+ gatherJsonKey
															+ ":"
															+ getTotleNum(dataList).toFixed(2)
															+ ",";
												} else if (gathers[j].indexOf("|") != -1) {
													sumColumns = gathers[j].split("|");
													if (ccolumns[n][k] == sumColumns[0]) {
														var gatherJsonKey = ecolumns[n][k].name;
														gatheJson = gatheJson
																+ gatherJsonKey
																+ ":'"
																+ sumColumns[1] + "',";
													}
												}
											}
										}
										gatheJson = "{" + gatheJson.substring(0, gatheJson.length - 1) + "}";
										jQuery("#list" + n).jqGrid(
														'footerData',
														'set',
														eval('(' + gatheJson + ')'));
									}
								}
							} else {
								myCharts[n].clear();
							}
						},
						gridComplete : function() {

						}
					});
	/* 页数显示 */
	jQuery("#list" + n).jqGrid('navGrid', '#pager' + n, {
		edit : false,
		add : false,
		del : false
	}, {}, {}, {}, {
		multipleSearch : true,
		multipleGroup : false
	});
	/* 二级表头 */
	if (groupHeaders[n] != []) {
		jQuery("#list"+n).jqGrid('setGroupHeaders', {
			useColSpanStyle : true,
			groupHeaders : groupHeaders[n]
		});
	}
	});
}
function expand() {
	$(".expandCollapse").attr("showattr", "Y");
	$(".expandCollapse").html("收起");
	$(".reportTable").show();
}
function packUp() {
	$(".expandCollapse").attr("showattr", "N");
	$(".expandCollapse").html("数据明细");
	$(".reportTable").hide();
}
function isJson(obj) {
	var isjson = typeof (obj) == "object"
			&& Object.prototype.toString.call(obj).toLowerCase() == "[object object]"
			&& !obj.length;
	return isjson;
}

/* 替换中文逗号 */
function replaceDot(str) {
	var oldValue = str;
	while (oldValue.indexOf("，") != -1) {
		str = oldValue.replace("，", ",");
		oldValue = str;
	}
	return oldValue;
}

/* 取数组的和 */
function getTotleNum(list) {
	var sum = 0;
	for (var i = 0; i < list.length; i++) {
		sum = sum + list[i] * 1;
	}
	return sum;
}

</script>
