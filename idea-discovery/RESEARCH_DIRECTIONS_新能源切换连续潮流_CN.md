# 新能源切换连续潮流 研究方向建议

> 交付对象：课题负责人、导师及合作方。用途：从两个独立研究方向中选择路线，每个方向均包含基础方案与深化方案。
> 本文提供研究思路、可追溯证据与最低验证设计，不将待验证假设写成已完成的创新点，不代替后续完整实验方案。调研日期：2026年10月11日。

术语约定：CPF为连续潮流（Continuation Power Flow），LVRT为低电压穿越（Low-Voltage Ride-Through），RES为新能源电源（Renewable Energy Sources）；SNB为鞍结分岔（Saddle-Node Bifurcation），LIB为限制诱导分岔（Limit-Induced Bifurcation）。静态极限、控制事件与时域振荡分别判定。

## 0. 一页速览

| 项 | 方向一 | 方向二 |
|---|---|---|
| 一句话问题 | 有限次连续潮流计算，怎样更有效地发现多个新能源独立出力组合中的低裕度工况？ | 相近的低电压穿越阈值距离，为何可能对应不同的多场站风险结果，静态判据何时适用？ |
| 基础方案：做什么、得到什么 | 在0至额定出力域，联合低裕度搜索、控制事件差异和全域探索分配计算预算；输出经复算的危险工况与搜索性能证据 | 在预先设计的独立出力切片中构造配对工况，比较静态阈值特征与时域结果；得到风险判据的适用范围及反例 |
| 深化方案：新增问题与贡献 | 研究事件条件下的裕度乐观误差校准及独立审计，给出有明确抽样假设的可靠性结论 | 构造多场站事件返回映射，研究进出切换扰动如何衰减或放大，以及局部循环吸引性质如何随事件顺序替换而改变 |
| 与另一方向的实质差异 | 贡献机制是外层搜索的预算分配与可靠性 | 贡献机制是静态特征的诊断有效性与动态切换机制解释 |
| 与已有代码关系（基础 / 深化） | 均直接复用已有内核；新增外层调度、校准和审计 | 均直接复用已有内核与动态模型；新增配对试验设计、事件日志分析和局部映射辨识 |
| 主要风险（基础 / 深化） | 事件标签未带来额外搜索收益 / 稀有事件组不足以支持校准 | 找不到稳健的差异配对 / 事件序列改变或擦边使局部映射失效 |
| 基础周期 / 深化额外周期及依据 | 基础按30天收敛范围；深化额外周期和模型条件见3.5 | 基础按30天收敛范围，以已有可运行动态模型为前提；深化额外周期见4.5 |
| 基础发表目标 / 深化目标与尚缺条件 | 基础对标CIYCEE 2026；深化面向IEEE Transactions on Power Delivery，仍需误差机制、规模验证及工程输送意义 | 基础对标CIYCEE 2026；深化面向IEEE Transactions on Power Delivery，仍需可重复映射、适用条件及输送系统证据 |

推荐顺序与理由：**优先方向一基础方案**，它直接对应简报中尚缺的多独立有功出力外层框架，30天内较易形成有对照的闭环。若已有Simulink模型可稳定复现多场站LVRT进出及衰减/持续振荡，且更重视机理解释，可优先方向二。两条路线均可独立开展；本次不替课题负责人作最终选择。

两个方向均保持新能源有功独立变化，不令所有新能源随内层负荷参数同比增长。全域最小裕度是研究对象，有限搜索所得最小值是数值发现；静态阈值与动态振荡分别取证。用户已明确当前代码细节重要性较低，因此按简报已有平台能力规划，接口和版本在实施阶段核对。


## 1. 输入与证据边界

### 1.1 来源范围与目标覆盖

- 研究简报：[研究简报](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/前置准备/RESEARCH_BRIEF_新能源切换连续潮流_CN.md>)。
- 文献报告：[实际文献调研报告](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/research-lit/新能源切换连续潮流_文献调研.md>)；实际文件名不同于技能默认模式，已按项目路径定位。上游质量状态为 `ready`，但仍不证明绝对创新性。
- 正式流程：[目标清单](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/paper-notes/_targets.json>)；人工下载PDF目录为 [fulltext-pdfs](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs>)。本轮没有外部检索或下载。
- 范围依报告来源元数据划分：IEEE、Engineering Village（EV）及CNKI人工下载的外部论文纳入；历史 `local_pdf` 排除，不回读、索取补件或凑数。没有用户授权local例外，没有用户豁免。
- 登记分母为35篇深度记录加5篇本地附录，共40条；排除14条后26篇均为必要目标。26个目标均核实身份并匹配26个去重PDF；缺件、歧义、来源待澄清、范围冲突、目录额外文件均为0。原报告无编号，P01–P35按其深度表顺序赋号，L-A01–05为附录；机器文件前缀不是论文ID。

下表记录实际阅读范围，不把涉及一页等同该页全文已读。“页:偏移–页:偏移”及“页:[起,止)”表示局部原文范围；纯页号/页段表示读取该物理页提取文字，仍不代表公式排版与推导已认证。所有纳入记录状态均为“已核验该范围”，不是“全文已核验”。表中PDF后的证据页为本报告取证定位，完整引文见审查记录。

| 目标ID/题名 | 来源元数据 | 纳入/排除及依据、local授权 | 必要性/竞争路线 | 匹配PDF或缺件/歧义 | 阅读/核验范围、异常处置、用户豁免 |
|---|---|---|---|---|---|
| P01 · 扩展CPF | IEEE Xplore Journals | 纳入；外部报告记录；无local例外 | 必要目标；R1 | [P01 · 扩展CPF](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/An_Extended_Continuation_Power_Flow_Method_for_Static_Voltage_Stability_Assessment_of_Renewable_Power_Generation-Penetrated_Power_Systems.pdf>)，PDF p. 4、5；身份已核实 | 摘要 1:380–1:1657；引言 1:1773–2:1277；结论 5:1017–5:1702；2:[0,5214)；4:[0,4318)；1:[0,500)；异常见1.2；无豁免 |
| P02 · SVG配置 | IEEE Xplore Journals | 纳入；外部报告记录；无local例外 | 必要目标；R4 | [P02 · SVG配置](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/SVG Configuration Scheme to Enhance Renewable Energy Accommodation Considering Voltage Stability Constraints in Renewable Power Grids.pdf>)，PDF p. 2、4、5；身份已核实 | 摘要 1:422–1:1732；引言 1:1880–2:1553；结论 5:1125–5:1794；2:[0,5407)；4:[0,3531)；1:[0,500)；异常见1.2；无豁免 |
| P03 · 高比例VSC稳定增强 | IEEE Xplore Journals | 纳入；外部报告记录；无local例外 | 必要目标；R1 | [P03 · 高比例VSC稳定增强](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/A_Static_Voltage_Stability_Enhancement_Method_for_Power_Systems_With_a_High_Proportion_of_Voltage_Source_Converters.pdf>)，PDF p. 1、9、12；身份已核实 | 摘要 1:329–1:1614；引言 1:1789–2:5426；结论 12:608–12:2391；3:[0,4837)；9:[0,3643)；1:[0,500)；异常见1.2；无豁免 |
| P04 · 最差裕度区间 | IEEE Xplore Journals | 纳入；外部报告记录；无local例外 | 必要目标；R2 | [P04 · 最差裕度区间](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Identification_of_the_Worst-Case_Static_Voltage_Stability_Margin_Interval_of_AC_DC_Power_System_Considering_Uncertainty_of_Renewables.pdf>)，PDF p. 3、4、12；身份已核实 | 摘要 1:358–1:1660；引言 2:888–3:668；结论 12:2842–13:206；1:[0,4446)；3:[0,4406)；4:[0,4792)；8:[0,5677)；12:[0,4197)；13:[0,8352)；1:[0,500)；异常见1.2；无豁免 |
| P05 · 模式切换裕度增强 | IEEE Xplore Journals | 纳入；外部报告记录；无local例外 | 必要目标；R2 | [P05 · 模式切换裕度增强](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Optimal_Enhancement_Control_of_Static_Voltage_Stability_Margin_for_AC_DC_Power_System_With_Renewables_Considering_Control_Mode_Switching_of_DC_Converter_Stations.pdf>)，PDF p. 3、4、10、11；身份已核实 | 摘要 1:415–1:1837；引言 1:3231–2:5168；结论 11:2828–11:5052；3:[0,5208)；4:[0,5509)；7:[0,4384)；8:[0,3969)；10:[0,4768)；11:[0,5958)；1:[0,500)；异常见1.2；无豁免 |
| P06 · 相关新能源稳定评估 | IEEE Xplore Journals | 纳入；外部报告记录；无local例外 | 必要目标；R2 | [P06 · 相关新能源稳定评估](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Power_System_Voltage_Stability_Evaluation_Considering_Renewable_Energy_With_Correlated_Variabilities.pdf>)，PDF p. 3、6、9；身份已核实 | 摘要 1:291–1:1722；引言 2:122–2:4872；结论 8:3262–9:1032；3:[0,4785)；6:[0,4158)；1:[0,500)；异常见1.2；无豁免 |
| P07 · 自适应LVRT设置 | IEEE Xplore Journals | 纳入；外部报告记录；无local例外 | 必要目标；R3 | [P07 · 自适应LVRT设置](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/A_Scalable_Method_of_Adaptive_LVRT_Settings_Adjustment_for_Voltage_Security_Enhancement_in_Power_Systems_With_High_Renewable_Penetration.pdf>)，PDF p. 3、8；身份已核实 | 摘要 1:319–1:1702；引言 1:1819–2:5599；结论 11:1366–11:2647；3:[0,4107)；8:[0,3197)；1:[0,500)；异常见1.2；无豁免 |
| P08 · 三相TPCPF | IEEE Xplore Journals | 纳入；外部报告记录；无local例外 | 必要目标；R1 | [P08 · 三相TPCPF](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/TPCPF_Three-Phase_Continuation_Power_Flow_Tool_for_Voltage_Stability_Assessment_of_Distribution_Networks_With_Distributed_Energy_Resources.pdf>)，PDF p. 2、4、5；身份已核实 | 摘要 1:394–1:1703；引言 1:1826–2:2946；结论 11:2491–12:309；4:[0,3190)；5:[0,4122)；1:[0,500)；异常见1.2；无豁免 |
| P09 · L指数承载力 | IEEE Conferences | 纳入；外部报告记录；无local例外 | 必要目标；R4 | [P09 · L指数承载力](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Renewable_Power_Hosting_Capacity_Assessment_Considering_L-Index_for_Static_Voltage_Stability.pdf>)，PDF p. 3、5；身份已核实 | 摘要 1:660–1:1737；引言 1:1832–1:4776；结论 5:701–5:1709；3:[0,5065)；4:[0,5635)；1:[0,500)；异常见1.2；无豁免 |
| P10 · 多馈入裕度指标 | IEEE Conferences | 纳入；外部报告记录；无local例外 | 必要目标；R2 | [P10 · 多馈入裕度指标](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Static_Voltage_Stability_Analysis_of_Renewable_Energy_Multi-Infeed_Systems_Based_on_Margin_Index.pdf>)，PDF p. 2、5、8；身份已核实 | 1:[6709,12736)；2:[5588,7337)；5:[5106,9692)；7:[6691,7177)；8:[3871,4535)；异常见1.2；无豁免 |
| P11 · 配电网最大接入比 | IEEE Conferences | 纳入；外部报告记录；无local例外 | 必要目标；R4 | [P11 · 配电网最大接入比](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Static_Voltage_Stability_Based_Maximum_Integration_Ratio_of_Distributed_Renewable_Energy_in_Distribution_Power_System.pdf>)，PDF p. 2、3、4；身份已核实 | 摘要 1:301–1:1143；引言 1:1266–1:4133；结论 4:2010–4:3285；2:[0,3088)；3:[0,2691)；1:[0,500)；异常见1.2；无豁免 |
| P12 · 相关新能源概率评估 | IEEE Conferences | 纳入；外部报告记录；无local例外 | 必要目标；R2 | [P12 · 相关新能源概率评估](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Probabilistic_Static_Voltage_Stability_Assessment_for_Distribution_Network_Considering_Correlated_Renewable_Energy.pdf>)，PDF p. 3、4、5；身份已核实 | 摘要 1:452–1:1360；引言 1:1472–1:4750；结论 5:1347–5:2520；3:[0,4404)；4:[0,3814)；1:[0,500)；异常见1.2；无豁免 |
| P13 · 故障期分布式光伏 | IEEE Conferences | 纳入；外部报告记录；无local例外 | 必要目标；R3 | [P13 · 故障期分布式光伏](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Static_Voltage_Stability_Analysis_and_Control_Strategy_of_Distribution_Network_with_High_Proportion_Distributed_PV_Generation_During_Fault.pdf>)，PDF p. 1、4；身份已核实 | 1:[0,5926)；2:[0,4760)；3:[0,3277)；4:[0,4612)；异常见1.2；无豁免 |
| P14 · 潮流静态稳定判据 | Engineering Village | 纳入；外部报告记录；无local例外 | 必要目标；R1 | [P14 · 潮流静态稳定判据](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Static_Voltage_Stability_Criterion_of_Renewable_Energy_Sources_based_on_Power_Flow_Analysis.pdf>)，PDF p. 2、5；身份已核实 | 1:[0,5118)；2:[0,3407)；4:[0,3944)；5:[0,5517)；异常见1.2；无豁免 |
| P15 · Krylov–Arnoldi框架 | Engineering Village | 纳入；外部报告记录；无local例外 | 必要目标；R1 | [P15 · Krylov–Arnoldi框架](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Jacobian-Free_Krylov-Arnoldi_Framework_for_Static_Voltage_Stability_Estimation_of_Power_Systems_With_100_Renewable_Energy.pdf>)，PDF p. 3；身份已核实 | 1:[0,6400)；2:[0,5333)；3:[0,4749)；11:[0,4568)；12:[0,5219)；异常见1.2；无豁免 |
| P16 · 多电压等级送出断面 | Engineering Village | 纳入；外部报告记录；无local例外 | 必要目标；R2 | [P16 · 多电压等级送出断面](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Static_Voltage_Stability_Analysis_of_Large_Scale_Renewable_Energy_Delivered_via_Multi-Voltage-Level_Transmission_Sections.pdf>)，PDF p. 1、4；身份已核实 | 1:[0,5876)；2:[0,3690)；4:[0,4540)；5:[0,3420)；异常见1.2；无豁免 |
| P17 · 短路故障LVRT静态稳定 | Engineering Village | 纳入；外部报告记录；无local例外 | 必要目标；R3 | [P17 · 短路故障LVRT静态稳定](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Research on Static Voltage Stability During Low-voltage Ride-through Under Short-circuit Fault Conditions in Renewable Energy Integrated Power Grids.pdf>)，PDF p. 3、11、12；身份已核实 | 1:[0,3544)；2:[0,1999)；3:[0,1998)；11:[0,2146)；12:[0,3636)；异常见1.2；无豁免 |
| P18 · VSC-HVDC协调控制 | Engineering Village | 纳入；外部报告记录；无local例外 | 必要目标；R4 | [P18 · VSC-HVDC协调控制](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Research_on_Coordinated_Active_and_Reactive_Power_Control_of_VSC-HVDC_Connected_Renewable_Energy_System_for_Enhancing_Static_Voltage_Stability.pdf>)，PDF p. 5、6；身份已核实 | 1:[0,5852)；2:[0,4469)；5:[0,4873)；6:[0,5576)；异常见1.2；无豁免 |
| P19 · VSC-HVDC稳定域 | Engineering Village | 纳入；外部报告记录；无local例外 | 必要目标；R2 | [P19 · VSC-HVDC稳定域](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Study_of_Static_Voltage_Stability_Region_Considering_Integration_of_Renewable_Energy_Through_VSC-HVDC_System.pdf>)，PDF p. 2、5；身份已核实 | 1:[0,5570)；2:[0,5743)；4:[0,4985)；5:[0,5949)；异常见1.2；无豁免 |
| P20 · 在线数据驱动裕度 | Engineering Village | 纳入；外部报告记录；无local例外 | 必要目标；R2 | [P20 · 在线数据驱动裕度](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Online_Data-Driven_Evaluation_Method_of_Static_Voltage_Stability_Margin_for_AC_DC_Hybrid_Power_Systems_Considering_Uncertainty_of_Renewable_Energy.pdf>)，PDF p. 8、9、16；身份已核实 | 1:[0,6315)；2:[0,7114)；8:[0,5541)；9:[0,5184)；16:[0,5679)；17:[0,5728)；18:[0,8902)；异常见1.2；无豁免 |
| P21 · 功率波动边界直接算法 | CNKI | 纳入；外部报告记录；无local例外 | 必要目标；R2 | [P21 · 功率波动边界直接算法](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/考虑新能源功率波动的静态电压稳定边界直接算法_李安然.pdf>)，PDF p. 3、4、5；身份已核实 | 1:[0,2752)；2:[0,3271)；3:[0,2563)；4:[0,2439)；5:[0,2620)；6:[0,4739)；异常见1.2；无豁免 |
| P22 · 构网场站与无功源配置 | CNKI | 纳入；外部报告记录；无local例外 | 必要目标；R4 | [P22 · 构网场站与无功源配置](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/考虑静态电压稳定的新能源基地构网型场站与无功源优化配置方法_赵冬梅.pdf>)，PDF p. 9、12；身份已核实 | 1:[0,999)；2:[0,2920)；3:[0,2033)；4:[0,1887)；9:[0,1928)；12:[0,3183)；异常见1.2；无豁免 |
| P23 · 新能源承载能力 | CNKI | 纳入；外部报告记录；无local例外 | 必要目标；R4 | [P23 · 新能源承载能力](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/计及静态电压稳定裕度的电力系统新能源承载能力评估方法_陈沁昊.pdf>)，PDF p. 3、9、10；身份已核实 | 1:[0,3109)；2:[0,2174)；3:[0,2111)；7:[0,1992)；9:[0,2188)；10:[0,4339)；异常见1.2；无豁免 |
| P24 · 风电并网静态稳定 | CNKI | 纳入；外部报告记录；无local例外 | 必要目标；R2 | [P24 · 风电并网静态稳定](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/风电并网系统的静态电压稳定性研究_葛飞飞.pdf>)，PDF p. 46、49、51、58；身份已核实 | 1–2；4；7–9；18–20；32；42–46；48–51；54–59；异常见1.2；无豁免 |
| P25 · PMU在线评估 | CNKI | 纳入；外部报告记录；无local例外 | 必要目标；R3 | [P25 · PMU在线评估](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/基于PMU数据的新能源场站静态电压稳定在线评估_孔贺.pdf>)，PDF p. 60、64、75、82、114；身份已核实 | 1–2；4–5；9–12；21–23；60–66；72–75；79–82；113–115；异常见1.2；无豁免 |
| P26 · 风电断面动态极限 | CNKI | 纳入；外部报告记录；无local例外 | 必要目标；R2 | [P26 · 风电断面动态极限](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/静态电压稳定约束下大规模风电送出断面动态极限研究_石子敬.pdf>)，PDF p. 27、28、37、43、63；身份已核实 | 1–2；4；7–10；13–14；21–22；26–29；31；37–38；42–46；62–65；异常见1.2；无豁免 |
| P27–P35（9条） | local_pdf，报告深度表历史本地来源 | 排除；无例外授权 | 不用于补路线 | 不读取或索取PDF | 未读取；无豁免 |
| L-A01–L-A05（5条） | local_pdf，报告本地候选附录 | 排除；无例外授权 | 不作为必要目标 | 不读取或索取PDF | 未读取；无豁免 |

目录额外文件：0。14条排除记录的逐篇题名及依据保存在目标清单中，没有以其他文件替代缺件。

| 竞争路线 | 纳入目标ID | 已核验的正文/等效内容范围 | 仅摘要级证据/缺口 | 影响与用户豁免依据 |
|---|---|---|---|---|
| R1：CPF扩展与模式/限流约束 | P01、P03、P08、P14、P15 | 涵盖扩展连续潮流（CPF）、控制模式、限流、PV–PQ与解析判据；未认证全部公式。实际页内范围见上表 | 本轮无仅摘要替代目标；未读页与未经核验公式不支持排他断言 | 有条件归纳；无豁免 |
| R2：多新能源组合、不确定性与最差裕度 | P04、P05、P06、P10、P12、P16、P19、P20、P21、P24、P26 | 涵盖区间/概率/最差裕度、全局搜索、代理与场景削减；这些通用组合不构成可直接复称的新颖点。实际页内范围见上表 | 本轮无仅摘要替代目标；未读页与未经核验公式不支持排他断言 | 有条件归纳；无豁免 |
| R3：LVRT阈值、故障期静态边界与动态风险 | P07、P13、P17、P25 | 低电压穿越（LVRT）最终脱网、故障稳态与控制诱导非光滑分岔均有正文证据；其模型须分别讨论。实际页内范围见上表 | 本轮无仅摘要替代目标；排除历史local后，PLL/电流环等其他动态机制不在本轮全文证据范围 | 有条件归纳；无豁免 |
| R4：承载能力、无功资源与控制配置 | P02、P09、P11、P18、P22、P23 | 涵盖承载力、SVG/构网配置及有无功协调；配置容量最大化不等同运行域最坏裕度。实际页内范围见上表 | 本轮无仅摘要替代目标；未读页与未经核验公式不支持排他断言 | 有条件归纳；无豁免 |

### 1.2 机器抽取与人工/agent 核验

机器清点见 [_inventory.json](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/paper-notes/_inventory.json>)，抽取见 [_extraction_summary.json](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/paper-notes/_extraction_summary.json>)：实际处理26个文件、468个物理页。清点阶段为9篇 `text_detected`、17篇 `needs_text_review`，这只是抽查信号；全页抽取的三类状态如下。

| 机器字段 | 允许状态 | 各状态数量/目标ID |
|---|---|---|
| `text_status` | `readable` / `needs_text_review` / `failed` | 2（P02、P07）/24（其余纳入目标）/0 |
| `section_status` | `candidates_located` / `incomplete` | 26（P01–P26）/0 |
| `status` | `extracted` / `needs_review` / `failed` | 0/26（P01–P26）/0 |

全部机器索引根级及章节 `review_status` 保持 `pending`；三段候选齐全也不构成阅读证明。章节索引与逐页原文由汇总中每条 `papers[].note` 及其 `raw_pages_file` 精确定位，未通配导入旧笔记。原文保存pypdf返回文字，不是视觉/OCR真值。摘要、引言、结论预览截断时，核验者按页补读并单独记录边界；`limitation_hits`只用作线索。

独立核验见 [_review.json](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/paper-notes/_review.json>)，与机器结果分开保存。26篇均记录源PDF/原文SHA-256、核验者、实际阅读范围、直接引文与准确物理页/字符偏移。81条引文逐字校验通过，文件hash一致。物理页从1开始，offset从0开始、结束位置不含边界；不用印刷页码冒充物理页。主agent抽查见 [_spotchecks.json](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/paper-notes/_spotchecks.json>)。

主要异常及处理如下；未经核验的公式和原文内部数值冲突不进入本报告性能结论。

- [P09 · L指数承载力](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Renewable_Power_Hosting_Capacity_Assessment_Considering_L-Index_for_Static_Voltage_Stability.pdf>)，PDF p. 4：场景文字与表格数值对应不一致，保留原文冲突，不引用其数值性能。
- [P18 · VSC-HVDC协调控制](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Research_on_Coordinated_Active_and_Reactive_Power_Control_of_VSC-HVDC_Connected_Renewable_Energy_System_for_Enhancing_Static_Voltage_Stability.pdf>)，PDF p. 5：误差文字与表格数据不一致，不采用冲突数值。
- [P10 · 多馈入裕度指标](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Static_Voltage_Stability_Analysis_of_Renewable_Energy_Multi-Infeed_Systems_Based_on_Margin_Index.pdf>)，PDF p. 2、8：重复字码层/可读英文层重新定界，并渲染视觉核对；不把乱码或参考文献计入证据。
- [P25 · PMU在线评估](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/基于PMU数据的新能源场站静态电压稳定在线评估_孔贺.pdf>)，PDF p. 75、113–115：关键固定其他风场有功假设已视觉核对；机器结论漏掉展望，审查范围修正为113–114，115为参考文献。
- [P26 · 风电断面动态极限](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/静态电压稳定约束下大规模风电送出断面动态极限研究_石子敬.pdf>)，PDF p. 9–14、62–64：机器引言仅覆盖局部；目录与正文核定绪论9–13，结论展望62–63，64参考文献页眉不纳入。
- 初次AES解密依赖问题已用预装Python环境解决，最终26篇均有非空逐页文本；没有把前几页少字或碎字自动判为扫描/OCR需求。
- 部分双栏、图表、公式含私用字符或字流错序。核验采用清晰叙述，不能据此转录未核实公式或声称复现了实验；章节边界问题写入独立记录，未改机器结果冒充自动成功。

论文链接使用真实绝对路径，仅承诺打开文章，页码为可见定位信息；未使用未经验证的页锚点。换机或移动文件后需重新映射路径。

### 1.3 证据 Gate

**通过，可进入限定证据范围的方向归纳。** 26个必要外部目标均已匹配、身份确认并取得正文或等效内容证据；不存在必要缺件、关键叙述不可读或影响本轮归纳的未解决核验问题。四条竞争路线均有证据，原文数值冲突已隔离，局部文字问题已按范围处理，未使用用户豁免替代验证。

通过Gate只表示材料足以支撑有边界的方向比较，不代表26篇全文通读、全部理论推导正确、候选方向具有绝对创新性或可获录用。没有8篇等凑数门槛；两方向还须通过独立性、深化增量和可执行性审查。所有局限限定为当前已读且可追溯的范围，“已读范围内未提及”不等于全文没有。

按用户后续要求，本轮减少代码细节关注；已有代码及平台验证以研究简报为背景，接口与事件输出在实施前确认，不作为文献方向归纳主线。基础及深化均遵守复用已有内核、不重新开发底层的约束。


## 2. 已有工作局限性矩阵

|论文|年份/刊源|处理的切换/约束|参数化与场景维度|验证手段|作者自述局限|文本未覆盖之处|出处|
|---|---|---|---|---|---|---|---|
|P01 · 扩展CPF|IEEE T-CAS II, 2024|CVRPG控制模式更新、扩展Jacobian|Bus-15负荷单参数增长；控制系数对比|传统/扩展CPF算例对比|优化CVRPG控制参数列为未来工作|已读范围：已读算例不是多个新能源独立出力箱域最危险搜索|[P01 · 扩展CPF](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/An_Extended_Continuation_Power_Flow_Method_for_Static_Voltage_Stability_Assessment_of_Renewable_Power_Generation-Penetrated_Power_Systems.pdf>)，PDF pp. 4, 5|
|P02 · SVG配置与稳定约束|IEEE Transactions on Circuits and Systems II: Express Briefs, 2025|MRSCR约束、SVG规划|全年场景聚类；配置成本与加权弃电量|双层规划算例及电压上升约束核验|SVG安装成本建模及相互作用效应留待后续|已读范围：MRSCR/故障后瞬态电压上升约束不能等同于切换CPF的SNB认证|[P02 · SVG配置](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/SVG Configuration Scheme to Enhance Renewable Energy Accommodation Considering Voltage Stability Constraints in Renewable Power Grids.pdf>)，PDF pp. 2, 4, 5|
|P03 · 高VSC占比静稳增强|IEEE Transactions on Power Systems, 2025|VSC限流、无功备用与电压优化|同步机/VSC有功按初值同比增长；负荷恒功率因数|多VSC与扩展IEEE39算例|未计VSC出力间歇变化、离散无功补偿；故障暂态超出范围|已读范围：已读增长场景不覆盖独立新能源全域组合|[P03 · 高比例VSC稳定增强](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/A_Static_Voltage_Stability_Enhancement_Method_for_Power_Systems_With_a_High_Proportion_of_Voltage_Source_Converters.pdf>)，PDF pp. 1, 9, 12|
|P04 · 最差SVSM区间识别|CSEE Journal of Power and Energy Systems, 2024|LCC灭角、VSC无功/电压模式切换|多RES区间不确定性及负荷增长|改进IEEE39/实际大系统；观察Q到V切换|后续考虑运行参数调整与裕度增强控制|已读范围：已读RES按恒功率因数；直流换流站切换不能冒充新能源LVRT进入退出|[P04 · 最差裕度区间](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Identification_of_the_Worst-Case_Static_Voltage_Stability_Margin_Interval_of_AC_DC_Power_System_Considering_Uncertainty_of_Renewables.pdf>)，PDF pp. 3, 4, 12|
|P05 · 计及直流切换的裕度增强|IEEE Transactions on Industry Applications, 2025|直流站按默认顺序切换、运行约束|IEEE39含3个RES各自出力区间|不同控制方案与多RES算例|仅正常运行；多个N−1故障下控制为未来研究|已读范围：已读多RES不确定性已有；与新能源LVRT事件机制仍须区分|[P05 · 模式切换裕度增强](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Optimal_Enhancement_Control_of_Static_Voltage_Stability_Margin_for_AC_DC_Power_System_With_Renewables_Considering_Control_Mode_Switching_of_DC_Converter_Stations.pdf>)，PDF pp. 3, 4, 10, 11|
|P06 · 相关波动与全局灵敏度|IEEE Transactions on Power Systems, 2018|相关随机变量、概率负荷裕度|Gaussian Copula与随机响应面|GSA与局部灵敏度/Sobol结果比较|稀疏自适应SRSM、黑箱应用列为未来研究|已读范围：变量平均重要性排序不提供最危险工况认证或事件边界覆盖证明|[P06 · 相关新能源稳定评估](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Power_System_Voltage_Stability_Evaluation_Considering_Renewable_Energy_With_Correlated_Variabilities.pdf>)，PDF pp. 3, 6, 9|
|P07 · 自适应LVRT阈值调整|IEEE Transactions on Sustainable Energy, 2022|LVRT末端恒定段阈值、脱网/无功限值事件|二进制并网状态、多条PV曲线跳转|算例包含6次脱网与1次无功限值事件|明确仅调整LVRT曲线最终恒定段；已读范围未见其他明确自述局限|已读范围：阈值脱网模型不是进出LVRT控制反复振荡模型；事件顺序使用本身已有|[P07 · 自适应LVRT设置](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/A_Scalable_Method_of_Adaptive_LVRT_Settings_Adjustment_for_Voltage_Security_Enhancement_in_Power_Systems_With_High_Renewable_Penetration.pdf>)，PDF pp. 3, 8|
|P08 · 三相TPCPF|IEEE Transactions on Industry Applications, 2021|PV-PQ、自适应步长、鼻点|负荷λ增长；三相不平衡、拓扑与DER模式|IEEE13、18母线、CIGRE13、136母线|已读范围未见明确自述局限|已读范围：所读参数化未给新能源独立出力箱域最危险搜索|[P08 · 三相TPCPF](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/TPCPF_Three-Phase_Continuation_Power_Flow_Tool_for_Voltage_Stability_Assessment_of_Distribution_Networks_With_Distributed_Energy_Resources.pdf>)，PDF pp. 2, 4, 5|
|P09 · L-index承载能力|2024 IEEE PES 16th Asia-Pacific Power and Energy Engineering Conference (APPEEC), 2024|L-index阈值、风光0至最大出力|IEEE30一风一光；不同选址与阈值|改进IEEE30优化算例|已读范围未见明确自述局限|已读范围：已读内容为承载力最大化，不是切换CPF路径/事件序列分析|[P09 · L指数承载力](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Renewable_Power_Hosting_Capacity_Assessment_Considering_L-Index_for_Static_Voltage_Stability.pdf>)，PDF pp. 3, 5|
|P10 · 多馈入源侧裕度指标|2024 IEEE 7th International Electrical and Energy Conference (CIEEC), 2024|恒功率因数；Thevenin等值|一个风场增长、其他有功固定、负荷平衡|增长方式及裕度指标算例比较|指标受Thevenin参数精度影响；等值保持电压-功率灵敏度假设|已读范围：已读逐站增长试验不是全组合最坏搜索|[P10 · 多馈入裕度指标](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Static_Voltage_Stability_Analysis_of_Renewable_Energy_Multi-Infeed_Systems_Based_on_Margin_Index.pdf>)，PDF pp. 2, 5, 8|
|P11 · 分布式新能源最大接入比|2024 5th International Conference on Clean Energy and Electric Power Engineering (ICCEPE), 2024|最大功率点、无功为0、过电压约束|分配规则下接入容量|配置与接入比例仿真|无功影响与环网配置列为未来研究|已读范围：所读求限对象为过电压接入容量，不能作为低电压SNB同指标对照|[P11 · 配电网最大接入比](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Static_Voltage_Stability_Based_Maximum_Integration_Ratio_of_Distributed_Renewable_Energy_in_Distribution_Power_System.pdf>)，PDF pp. 2, 3, 4|
|P12 · 相关新能源概率静稳|2020 5th Asia Conference on Power and Electrical Engineering (ACPEE), 2020|KDE/Copula相关输入|Sobol准蒙特卡洛外层逐样调用CPF|QMC与简单随机抽样比较|算例风电比例较小，用以解释相关性影响较小|已读范围：概率分布精度不等于低概率危险组合或全域最差值认证|[P12 · 相关新能源概率评估](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Probabilistic_Static_Voltage_Stability_Assessment_for_Distribution_Network_Considering_Correlated_Renewable_Energy.pdf>)，PDF pp. 3, 4, 5|
|P13 · 故障期分布式PV静稳控制|2025 International Conference on New Power System Technology (PowerCon), 2025|对称故障、LVRT电流相角约束|主网侧DG容量、电气距离/故障参数|MATLAB/Simulink：传统LVRT对比|已读范围未见明确自述局限|已读范围：已读建模与实验聚焦故障期间；未给独立多有功组合及LVRT进出序列|[P13 · 故障期分布式光伏](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Static_Voltage_Stability_Analysis_and_Control_Strategy_of_Distribution_Network_with_High_Proportion_Distributed_PV_Generation_During_Fault.pdf>)，PDF pp. 1, 2, 3, 4|
|P14 · 基于潮流的静稳判据|2025 5th International Conference on Electrical Engineering and Computer Technology (IC2ECT 2025), 2025|潮流Jacobian奇异、单机无穷大等值|有功增长、无功变化及双VSC有限试验|MATLAB/Simulink单机与双站|已读范围未见明确自述局限|已读范围：有限双站例子不能外推至任意多维控制事件边界|[P14 · 潮流静态稳定判据](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Static_Voltage_Stability_Criterion_of_Renewable_Energy_Sources_based_on_Power_Flow_Analysis.pdf>)，PDF pp. 1, 2, 4, 5|
|P15 · JFKA限流与静稳估计|IEEE Transactions on Automation Science and Engineering, 2026|S型平滑限流、GFM/GFL及PQ/PV模式|负荷增长、限流容量/区域变化|改进IEEE39及118算例|已读范围未见明确自述局限；限流平滑是明确建模选择|已读范围：已读范围未给LVRT进入退出滞回等价证明；限流切换可先于SNB，不能混称SNB|[P15 · Krylov–Arnoldi框架](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Jacobian-Free_Krylov-Arnoldi_Framework_for_Static_Voltage_Stability_Estimation_of_Power_Systems_With_100_Renewable_Energy.pdf>)，PDF pp. 1, 2, 3, 11, 12|
|P16 · 多电压等级断面静稳|2025 International Conference on New Power System Technology (PowerCon 2025), 2025|串并联断面耦合、实际运行裕度|近远端出力、支路功率分布|简化机理与冀北实际电网仿真|近端出力到远端极限是难解析非线性隐式关系；建议仿真/查表|已读范围：已读范围未给多控制事件切换边界认证；统一出力可能保守或乐观是已有结论|[P16 · 多电压等级送出断面](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Static_Voltage_Stability_Analysis_of_Large_Scale_Renewable_Energy_Delivered_via_Multi-Voltage-Level_Transmission_Sections.pdf>)，PDF pp. 1, 2, 4, 5|
|P17 · 故障LVRT静稳裕度|Proceedings of the Chinese Society of Electrical Engineering, 2025|受控电流源、对称/不对称故障、虚拟阻抗|确定故障后的固定电流角；多源试验逐节点增电流|单源及IEEE33多源仿真|后续需考虑不同LVRT控制策略及更多场景|已读范围：故障稳态LTSVSMI不是进出LVRT动态振荡认证；已读多源试验其他DG固定|[P17 · 短路故障LVRT静态稳定](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Research on Static Voltage Stability During Low-voltage Ride-through Under Short-circuit Fault Conditions in Renewable Energy Integrated Power Grids.pdf>)，PDF pp. 1, 2, 3, 11, 12|
|P18 · VSC-HVDC有无功协调|2025 International Conference on Power System Technology (ICPST 2025), 2025|容量/电压约束、L-index目标|仅有功/仅无功/协调三策略|PSO优化与灵敏度仿真|其他电压稳定指标的影响留待后续|已读范围：L-index优化不能直接替代CPF极限/事件序列；不采用文内误差<3%的不一致数值|[P18 · VSC-HVDC协调控制](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Research_on_Coordinated_Active_and_Reactive_Power_Control_of_VSC-HVDC_Connected_Renewable_Energy_System_for_Enhancing_Static_Voltage_Stability.pdf>)，PDF pp. 1, 2, 5, 6|
|P19 · VSC-HVDC稳定域近似|IEEE Power and Energy Society General Meeting (PESGM 2025), 2025|动态P-Q限额、直流主从/下垂控制|两RES侧VSC二维出力域；0.1pu至额定搜索|四端HVDC近似模型对照全局搜索|明确小范围直流电压变化近似；已读范围未见另列未来局限|已读范围：已有二维域与全局搜索；已读近似模型未给LVRT进出事件边界|[P19 · VSC-HVDC稳定域](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Study_of_Static_Voltage_Stability_Region_Considering_Integration_of_Renewable_Energy_Through_VSC-HVDC_System.pdf>)，PDF pp. 1, 2, 4, 5|
|P20 · LightGBM-SHAP-KDE裕度预测|IEEE Transactions on Industry Applications, 2026, Article in Press|PQ风光、PV-PQ无功约束、AC/DC控制|Copula/LHS/聚类、多源负荷扰动|IEEE39/Polish2383；噪声缺失、拓扑变化|拓扑变化后原训练集精度恶化，需要更新（文内观察）|已读范围：已读范围未给LVRT事件序列预测或极端尾部覆盖保证；已有CPF标签和外层代理|[P20 · 在线数据驱动裕度](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Online_Data-Driven_Evaluation_Method_of_Static_Voltage_Stability_Margin_for_AC_DC_Hybrid_Power_Systems_Considering_Uncertainty_of_Renewable_Energy.pdf>)，PDF pp. 1, 2, 8, 9, 16, 17, 18|
|P21 · 全导数仿射区间算法|太阳能学报, 2026|SNB与LIB、无功限制|独立有功区间；14节点±30%、118节点±10%|对照AA-CPF、MC-CPF、MC-DM|非线性仿射可能漏覆盖；系数扩张处理；DDM不收敛则无法计算|已读范围：已读范围未给0至额定整个域与LVRT进出认证；不能称其忽略LIB或有严格全局包络|[P21 · 功率波动边界直接算法](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/考虑新能源功率波动的静态电压稳定边界直接算法_李安然.pdf>)，PDF pp. 1, 2, 3, 4, 5, 6|
|P22 · 构网场站与无功源配置|华北电力大学学报(自然科学版), 2026，网络首发|gSCR、无功容量、网损与稳定裕度|构网选址/容量和无功多目标规划|西北基地26节点、16风光场站；PowerFactory|明确未计GFM/GFL暂态控制交互|已读范围：规划静态配置证据不足以推出动态故障/进出切换风险结论|[P22 · 构网场站与无功源配置](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/考虑静态电压稳定的新能源基地构网型场站与无功源优化配置方法_赵冬梅.pdf>)，PDF pp. 1, 2, 3, 4, 9, 12|
|P23 · 计及裕度的承载能力评估|电网技术, 2026, 50(08):3178-3190|奇异值下界、完整交流潮流、PQ/Q-V下垂|节点容量分配及固定下垂参数|改进IEEE30；MATLAB/IPOPT|暂态约束、时空相关出力波动待研究；固定下垂参数限制自由度|已读范围：承载力最大化不同于固定额定出力域内最危险裕度；未给LVRT状态机|[P23 · 新能源承载能力](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/计及静态电压稳定裕度的电力系统新能源承载能力评估方法_陈沁昊.pdf>)，PDF pp. 1, 2, 3, 7, 9, 10|
|P24 · 风电并网静态电压稳定|辽宁工业大学硕士学位论文, 2024|改进CPF、自适应步长、SNB灵敏度|蒙特卡洛场景与裕度/概率距离削减|IEEE14/39；300场景削减35的文内试验|明确未研究动态/暂态；需研究其他分布式电源组合|已读范围：已读范围未给保持LVRT事件边界的场景削减误差控制|[P24 · 风电并网静态稳定](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/风电并网系统的静态电压稳定性研究_葛飞飞.pdf>)，PDF pp. 46, 49, 51, 58|
|P25 · PMU场站静稳在线评估|华北电力大学(北京)博士学位论文, 2024|HLINB/SNB、无功控制及PV-PQ、SOCP|待评场站增出力时其他风场有功固定|BPA阈值两侧时域；3机9节点/10机39节点|特定算例过程分析、数学机理尚欠；简化LVRT未考虑Crowbar及换流器模型|已读范围：可研究多独立有功变化如何改变边界，但HLINB识别及无功约束求极限均已有|[P25 · PMU在线评估](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/基于PMU数据的新能源场站静态电压稳定在线评估_孔贺.pdf>)，PDF pp. 60, 64, 75, 82, 114|
|P26 · 风电送出断面工况相关极限|华北电力大学(北京)硕士学位论文, 2024|PV鼻点/裕度；PSASP含高低穿参数|38风场聚6场景；内层风机/负荷均匀增长；6区域输入|PSASP断面仿真及GA-BP训练测试|场景5因异于其他场景被合为一类，内部规律不明；网络表达式庞大|已读范围：已读求限未给HLINB判据；相似性聚类是否保持控制边界待检验，不能预设失败|[P26 · 风电断面动态极限](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/静态电压稳定约束下大规模风电送出断面动态极限研究_石子敬.pdf>)，PDF pp. 27, 28, 37, 43, 63|

**共性候选缺口（不是方向结论）**

1. **多独立出力与控制事件交叉的证据仍有限。** [P25 · PMU在线评估](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/基于PMU数据的新能源场站静态电压稳定在线评估_孔贺.pdf>)，PDF pp. 75固定其他风场有功；[P10 · 多馈入裕度指标](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Static_Voltage_Stability_Analysis_of_Renewable_Energy_Multi-Infeed_Systems_Based_on_Margin_Index.pdf>)，PDF pp. 5逐站变化；但[P04 · 最差裕度区间](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Identification_of_the_Worst-Case_Static_Voltage_Stability_Margin_Interval_of_AC_DC_Power_System_Considering_Uncertainty_of_Renewables.pdf>)，PDF pp. 3, 4, 12和[P05 · 模式切换裕度增强](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Optimal_Enhancement_Control_of_Static_Voltage_Stability_Margin_for_AC_DC_Power_System_With_Renewables_Considering_Control_Mode_Switching_of_DC_Converter_Stations.pdf>)，PDF pp. 3, 4, 10已处理多RES不确定性和直流站切换。因此有限问题只能定位到不同类型事件、独立出力与危险工况覆盖的交叉，不可泛称“切换+不确定性无人研究”。
2. **全局范围、概率误差和边界认证应分开。** [P21 · 功率波动边界直接算法](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/考虑新能源功率波动的静态电压稳定边界直接算法_李安然.pdf>)，PDF pp. 3, 5承认漏覆盖/收敛依赖；[P20 · 在线数据驱动裕度](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Online_Data-Driven_Evaluation_Method_of_Static_Voltage_Stability_Margin_for_AC_DC_Hybrid_Power_Systems_Considering_Uncertainty_of_Renewable_Energy.pdf>)，PDF pp. 8, 9, 16提供概率预测和模型更新；[P06 · 相关新能源稳定评估](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Power_System_Voltage_Stability_Evaluation_Considering_Renewable_Energy_With_Correlated_Variabilities.pdf>)，PDF pp. 3, 6量化变量重要性。上述证据不能直接替代全域最危险值认证；候选研究必须明示统计或数值结论的适用范围。
3. **降维/削减可能遗漏稀有边界是待检验假设。** [P24 · 风电并网静态稳定](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/风电并网系统的静态电压稳定性研究_葛飞飞.pdf>)，PDF pp. 49, 51已将裕度灵敏度用于场景削减；[P26 · 风电断面动态极限](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/静态电压稳定约束下大规模风电送出断面动态极限研究_石子敬.pdf>)，PDF pp. 28, 43, 63给出聚类、区域代理及异质场景局限。不能预先断言这些算法必然漏检，需要针对事件边界的对照证据。
4. **不同稳定极限不应混称。** [P15 · Krylov–Arnoldi框架](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Jacobian-Free_Krylov-Arnoldi_Framework_for_Static_Voltage_Stability_Estimation_of_Power_Systems_With_100_Renewable_Energy.pdf>)，PDF pp. 3限流切换可先于鞍点；[P25 · PMU在线评估](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/基于PMU数据的新能源场站静态电压稳定在线评估_孔贺.pdf>)，PDF pp. 60, 64区分HLINB与SNB；[P17 · 短路故障LVRT静态稳定](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Research on Static Voltage Stability During Low-voltage Ride-through Under Short-circuit Fault Conditions in Renewable Energy Integrated Power Grids.pdf>)，PDF pp. 3, 11, 12处理故障LVRT稳态电流极限；[P07 · 自适应LVRT设置](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/A_Scalable_Method_of_Adaptive_LVRT_Settings_Adjustment_for_Voltage_Security_Enhancement_in_Power_Systems_With_High_Renewable_Penetration.pdf>)，PDF pp. 3, 8处理阈值脱网事件。这些结论不彼此等价，也不能单凭潮流不收敛判振荡。

**不应再单独作为创新的既有工作**

- 外层抽样逐次调用CPF和概率裕度：[P12 · 相关新能源概率评估](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Probabilistic_Static_Voltage_Stability_Assessment_for_Distribution_Network_Considering_Correlated_Renewable_Energy.pdf>)，PDF pp. 3, 5；基于裕度的场景削减：[P24 · 风电并网静态稳定](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/风电并网系统的静态电压稳定性研究_葛飞飞.pdf>)，PDF pp. 49, 51。
- 二维新能源出力稳定域与全局搜索对照：[P19 · VSC-HVDC稳定域](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Study_of_Static_Voltage_Stability_Region_Considering_Integration_of_Renewable_Energy_Through_VSC-HVDC_System.pdf>)，PDF pp. 5；多RES出力区间和直流控制模式切换：[P04 · 最差裕度区间](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Identification_of_the_Worst-Case_Static_Voltage_Stability_Margin_Interval_of_AC_DC_Power_System_Considering_Uncertainty_of_Renewables.pdf>)，PDF pp. 3, 4, 12、[P05 · 模式切换裕度增强](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Optimal_Enhancement_Control_of_Static_Voltage_Stability_Margin_for_AC_DC_Power_System_With_Renewables_Considering_Control_Mode_Switching_of_DC_Converter_Stations.pdf>)，PDF pp. 10。
- 代理模型、特征排序和概率裕度估计：[P20 · 在线数据驱动裕度](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Online_Data-Driven_Evaluation_Method_of_Static_Voltage_Stability_Margin_for_AC_DC_Hybrid_Power_Systems_Considering_Uncertainty_of_Renewable_Energy.pdf>)，PDF pp. 8, 9, 16；6区域功率到断面极限的代理：[P26 · 风电断面动态极限](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/静态电压稳定约束下大规模风电送出断面动态极限研究_石子敬.pdf>)，PDF pp. 43。换回归器本身不足以形成贡献。
- LVRT诱导HLINB识别、与SNB区分、无功限额下求场站极限：[P25 · PMU在线评估](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/基于PMU数据的新能源场站静态电压稳定在线评估_孔贺.pdf>)，PDF pp. 60, 64, 75；事件顺序记录和阈值优化：[P07 · 自适应LVRT设置](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/A_Scalable_Method_of_Adaptive_LVRT_Settings_Adjustment_for_Voltage_Security_Enhancement_in_Power_Systems_With_High_Renewable_Penetration.pdf>)，PDF pp. 3, 8。
- 区间法同时考虑SNB与LIB：[P21 · 功率波动边界直接算法](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/考虑新能源功率波动的静态电压稳定边界直接算法_李安然.pdf>)，PDF pp. 3, 4, 5；模式切换可能先于鞍点：[P15 · Krylov–Arnoldi框架](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Jacobian-Free_Krylov-Arnoldi_Framework_for_Static_Voltage_Stability_Estimation_of_Power_Systems_With_100_Renewable_Energy.pdf>)，PDF pp. 3；不能将其作为未经研究的新现象。

本地绝对路径链接适用于当前机器；移动语料或换机后需重新映射。

## 3. 方向一：有限计算预算下，面向控制事件变化的危险出力组合搜索

### 3.1 解决的具体问题

在每个新能源场站有功均可从0独立变化至额定值、底层切换连续潮流（CPF）保持不变的条件下，**把额外计算分配给“裕度低”和“相邻工况事件不同”的区域，能否比同等CPF调用预算的通用抽样与优化，更稳定地找到低裕度组合？**

例如，两组出力总量接近、空间距离很近的工况，可能分别先发生无功触限和低电压穿越（LVRT）控制切换。如果只按工况距离删减场景，或只围绕目前最小值加密，可能忽略事件发生顺序改变的一侧。这里的“可能”是要检验的假设，不是已经取得的结果；如果危险值并不集中在这些区域，事件信息就没有额外价值。

本文只在给定拓扑、控制参数、初始模式和负荷增长/功率平衡规则下寻找**已发现最小静态裕度**。全域是搜索范围，不代表已经证明全局最优。LVRT阈值距离单独报告，不能自动当作失稳点；动态振荡由时域验证另行判断。

### 3.2 现有工作的局限性

- [P04 · 最差裕度区间](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Identification_of_the_Worst-Case_Static_Voltage_Stability_Margin_Interval_of_AC_DC_Power_System_Considering_Uncertainty_of_Renewables.pdf>)，PDF pp. 3–4、12，以及[P05 · 模式切换裕度增强](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Optimal_Enhancement_Control_of_Static_Voltage_Stability_Margin_for_AC_DC_Power_System_With_Renewables_Considering_Control_Mode_Switching_of_DC_Converter_Stations.pdf>)，PDF pp. 3–4、10：已有多新能源不确定区间、最差裕度和直流控制模式切换；RES本身按恒功率因数建模。因此，本方向不能把“多出力＋切换＋最坏裕度”当作新贡献，具体比较对象应是本项目RES控制事件对**有限预算危险工况发现**的影响。
- [P24 · 风电并网静态稳定](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/风电并网系统的静态电压稳定性研究_葛飞飞.pdf>)，PDF pp. 49、51：已经用SNB点裕度灵敏度和概率距离做场景削减。[P26 · 风电断面动态极限](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/静态电压稳定约束下大规模风电送出断面动态极限研究_石子敬.pdf>)，PDF pp. 28、43、63：已有典型场景及多区域出力代理，作者还指出某类场景因与其他场景差异大而被聚合。有限推断：上述已读方法没有给出“削减后保持LVRT事件变化附近低裕度工况”的验证，不能预设这些方法必然漏检。
- [P20 · 在线数据驱动裕度](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Online_Data-Driven_Evaluation_Method_of_Static_Voltage_Stability_Margin_for_AC_DC_Hybrid_Power_Systems_Considering_Uncertainty_of_Renewable_Energy.pdf>)，PDF pp. 8–9、16：已有外层抽样、CPF标签和机器学习概率预测，且有拓扑变化后的更新；已读标签采用恒功率因数PQ新能源。单纯换回归器或做CPF外层不是差异点。
- [P21 · 功率波动边界直接算法](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/考虑新能源功率波动的静态电压稳定边界直接算法_李安然.pdf>)，PDF pp. 3、5：作者说明非线性仿射可能漏覆盖，并依赖直接法收敛。因此应把数值参考误差、统计漏检率和严格全域下界分开，本方向不承诺最后一种。

归纳：当前证据支持研究“控制事件变化是否值得占用额外搜索预算，以及如何揭示尚未发现危险工况的风险”，不支持宣称新定义了多新能源最坏裕度问题。

### 3.3 基础方案：可独立成文的研究闭环

先用均匀覆盖的少量工况探路，再把新增CPF计算分成三部分：继续探索未覆盖空间、核实目前最危险区域、查清事件类型改变的位置。最终交付一条“用了多少次计算，找到多危险的组合”的性能曲线，以及每个危险点对应的事件解释。基础方案对标30天形成可投CIYCEE 2026的稿件材料；会议实际征稿时间另行确认，当前不承诺录用。

1. **输入与研究边界。** 输入各场站额定有功、0至额定的独立取值范围、既有网络和控制参数；每次CPF运行中新能源有功固定，仍按既有负荷/同步机规则推进。不同组合必须使用同一功率平衡规则，并检查基态可行性；零有功时的并网/无功状态采用既有模型设定。统计上无需假定真实风光出力独立，所谓“独立变化”指搜索变量没有统一比例约束。真正的气象联合分布不是基础阶段必需输入。
2. **关键方法与操作步骤。** 先做空间填充抽样；保存每点的静态终止类型、裕度、事件站点/类型/顺序和求解状态。用邻近点构成局部比较：若两端事件标签不同，追加中间点及边界两侧点；在当前低裕度点邻域追加小范围扰动；始终保留一部分预算给全域探索。三个队列轮流分配调用，且预算比例、优先级与同优先级处理规则在测试前固定。邻点标签不同只是一种加密启发，不保证定位全部不连续边界；两端同标签也可能隐藏危险区域，因此必须保留全域探索。用等容差重新计算最终候选，排除求解误差造成的虚假低值。新增的是**事件差异触发的预算分配与候选复核规则**，不修改CPF方程、步长或事件求解器。
3. **输出与待检验结论。** 输出最危险候选、查询成本、终止类型、事件记录及基态不可行/数值未解决清单。研究假设H1：在事件类型发生变化的测试系统中，事件队列比纯低值加密更少错过低裕度区域；H2：全域探索队列可以降低陷入局部危险区的风险。两者均通过消融检验，不成立时不能宣称所提分配优越。
4. **最低必要验证。** 以已有可运行小系统的2个新能源变量做加密网格数值参考；再以既有中等系统的3个或更多变量检查预算扩展性，参考集独立于搜索集且明显更密。保留平滑工况、单一主导事件、相邻事件竞争三类测试，不只展示成功案例；用已有Simulink模型核对少量危险候选及邻近安全工况，RTLAB复核最有代表性的一组，不以硬件测试代替搜索误差对比。若2变量也没有事件变化，应先否定或缩小H1，不强行加大模型复杂度。

裕度统一定义为：在一个可行基态及固定增长路径上，从起始点到**首个经现有方法确认的静态可行极限**可增加的系统总负荷，单位MW。鞍结分岔（SNB）、限制诱导极限分别标记；LVRT进入事件本身不自动终止该指标。只有求解失败而无物理证据的点标“未解决”，不赋零裕度也不删除。若内核仅输出无量纲增长参数，用固定负荷增长方向转换为MW，并保留原参数。有限样本最小值是在“该域、该路径、该初始模式”下的上侧最坏值估计；有未解决点时明确不完整。

### 3.4 深化方案：新增问题与实质贡献

基础方案即使找到较低裕度，也不能说明“没找到更危险点，是因为确实很少，还是算法漏看了”。深化主线是**把自适应搜索与独立危险遗漏审计连接起来，并让事件区域的校准误差反馈到下一轮预算分配**。这研究的是算法风险与误差解释，不是系统动态稳定证明。

代理与数据分流先明确：仅用搜索训练集拟合一个轻量裕度回归代理，输入为各站额定值归一化后的独立有功，输出为MW裕度；统一校准与事件分层校准使用相同代理族和训练预算。每个检查点冻结代理，另设不参与训练的校准池与未触碰的最终审计池，分别用于误差分位数估计与遗漏检验。真实事件层由CPF确认；若另用事件分类器，其预测层不能继承真实层的条件保证。代理误差校准与下述二项遗漏审计是两个不同结论，不能互相替代。

具体做法：在固定检查点冻结搜索器与当前最小值，另取从未参与训练或选点的审计样本，检验是否存在比当前值至少低一个工程容差的工况。审计既有按全域参考分布独立抽取的一组，也可有预先定义的事件邻域分层组；后者报告各自条件结果，不混成全域保证。对有足够独立样本的层估计“裕度被高估”的单侧误差分位数，供下一轮加密排序；资料不足或新事件层不外推置信界，直接分配真实CPF查询。每轮更新以后，下次审计必须使用新样本或预先分割的数据，不能把已参与选点的数据重新包装成独立验证。

| 对比项 | 基础方案已做 | 深化方案新增 | 新增结论及验证方式 |
|---|---|---|---|
| 研究问题与适用边界 | 固定预算找到多少低裕度组合 | 指定参考分布下，尚未发现的显著更危险区域占比多大；哪些事件层特别容易乐观估计 | 冻结检查点的独立审计、事件分层误差和失覆盖率 |
| 模型、算法或理论分析 | 三队列选点与候选复核 | 单侧误差校准、未知事件层拒绝外推、审计结果驱动的下一轮预算更新；为多次检查分配错误概率额度 | 推导独立审计的有限样本上界及其前提；对照去掉分层、去掉拒绝、复用训练数据的结果 |
| 能解释或保证的性质 | 经验上更小的已发现裕度 | 对“比当前最小值再低指定容差”的集合给出概率质量上界，或明确审计失败 | 独立重复实验检查标称覆盖；更换参考分布检验外推失效 |

- **成立前提与失效条件。** 审计工况来自明确且固定的参考分布；每一冻结阶段内独立同分布；求解标签的容差受控。自适应训练样本不满足这些条件，不能直接套用可交换性。按真实事件标签分层的条件覆盖，需要在独立审计点完成CPF后才知道真实层；用预测标签选出的层不自动继承同一保证。极少样本层、未解决点过多或漂移使覆盖失效时必须返回“不足以审计”，不能合并成成功结论。
- **统计结论的限度。** 例如，在冻结阈值下独立抽取n个点且无漏检，一侧置信度为1−α时，遗漏集合的参考概率质量上界为1−α^(1/n)；n是独立审计数，α是预设错误概率。它约束体积/概率质量，**不排除极小甚至零测度危险集合，也不约束真正全局最小裕度误差**。多次检查需控制总错误概率。该式是拟采用的标准统计工具，不作为原创理论。
- **贡献边界。** 候选增量在于控制事件变化导致乐观误差的机制证据，以及如何用可审计的反馈重新分配CPF预算；如果仅套用一个统计公式或换代理模型，仍不足以形成深化贡献。
- **失败时可保留的成果。** 校准不稳定时，保留基础搜索的可重复性能结果和不适用事件区域，不给概率保证。若基础搜索也未优于基线，保留有效反例及失败边界，但须重新评估是否足以独立成文。
- **面向IEEE Transactions on Power Delivery仍需补齐。** 需要可复查的误差/遗漏结论、跨网络的传输系统应用价值、强对照和实质性能证据；“增加一组RTLAB波形”不能补足方法贡献。该方向与期刊适配尚待甲方判断，不以目标刊名代替结果质量。

### 3.5 所需仿真平台、模型与预期难度

| 项 | 基础方案所需 | 深化方案额外所需 |
|---|---|---|
| 平台与测试系统 | MATLAB；已有小系统2站、中等系统3站以上；已有Simulink/RTLAB | 更多独立重复批次及一个未参与设计的网络/运行条件，仍使用现有平台 |
| 可复用代码及与内核的关系 | **直接复用内核**；外层设置有功、调用与记录输出 | **直接复用内核**；审计、校准和预算反馈在外层完成 |
| 需新增模型或模块 | 工况生成、邻近事件比较、预算队列、结果缓存与参考误差计算 | 独立数据分流、分层校准、拒绝外推和顺序审计统计；无需新变流器模型 |
| 数据、设备与其他资源 | 既有算例/额定功率及模型参数；现有硬件少量复核 | 更高CPF总预算，记录随机种子、原始审计数据；无需强求历史实测分布 |
| 周期估计及依据 | 30天：第1周固定域/指标与跑通基线；第2周外层策略；第3周公平对照/验证；第4周分析成文 | 预计另加6–10周作为规划量级；取决于事件稀有度和独立审计开销，非工期保证 |
| 难度评级与理由 | 中；主要难点是公平预算与事件差异是否有额外信息 | 高；需处理自适应偏置、稀有事件和审计成本，不能用平均误差替代尾部 |
| 主要风险与应对 | 事件不改变低值分布则H1失败；保留纯低值与全域探索基线作真实反证 | 审计可能比搜索更贵；若总成本无优势，限于离线高可信评估，或不进入深化 |

按简报把可运行内核视为前提，不展开代码审查。实施仅确认现有输出可区分哪些事件及终止状态；退出LVRT功能不从描述自动推定。未确认的退出事件不进入基础标签，动态退出可由已有时域记录核对，但不据此宣称静态内核已经支持退出。

### 3.6 基线方法与可量化指标

| 层次 | 对照组或消融设计 | 隔离的因素 / 回答的问题 |
|---|---|---|
| 基础 | 独立随机、拉丁超立方或Sobol准蒙特卡洛；均使用相同切换CPF | 仅空间覆盖能达到什么程度；外层抽样已有，见[P12 · 相关新能源概率评估](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Probabilistic_Static_Voltage_Stability_Assessment_for_Distribution_Network_Considering_Correlated_Renewable_Energy.pdf>)，PDF pp. 3、5 |
| 基础 | 多起点无导数搜索；纯低裕度局部加密；事件队列关闭；全域队列关闭 | 是否优于通用优化，以及事件/探索两种信息分别是否必要 |
| 基础 | 相同场景库按出力距离削减、按裕度敏感度削减的可复现简化基线 | 避免只击败弱随机基线；对应[P24 · 风电并网静态稳定](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/风电并网系统的静态电压稳定性研究_葛飞飞.pdf>)，PDF pp. 49、51的既有思路，不能冒称完整复现其论文 |
| 深化 | 本方向基础搜索；统一误差校准；事件分层但无拒绝；有独立审计但不反馈预算 | 隔离事件分层、未知层拒绝与审计反馈的增量；所有组计入审计成本 |

| 层次 | 指标 | 定义、计算方式与单位 | 支持 / 否定假设的判据及依据 |
|---|---|---|---|
| 基础 | 数值参考差距 | 已发现最小裕度减去独立加密参考集最小裕度，MW；参考网格继续细化观察变化 | 相同总预算下差距及跨种子分布更小支持H1；若搜索找到比参考更低点，更新参考并报告，不能截成0冒充严格真值 |
| 基础 | 危险工况发现率 | 事先规定裕度阈值后，重复运行中发现至少一个低于阈值组合的比例 | 事件队列相对纯低值加密有稳定改善才支持H1；无改善或变差即反证 |
| 基础 | 成本与可解性 | CPF总调用数、总耗时s、数值未解决占比；包括失败调用与最终复核 | 优势需在相同容差和总成本下成立；不能靠丢弃失败点制造精度 |
| 深化 | 未发现危险质量及审计覆盖 | 独立审计中“比冻结最小值低超过容差”的频率与单侧上界；事件层分别计数 | 在预先指定分布和重复实验中检验标称覆盖；不作全域最优证书 |
| 深化 | 乐观误差与拒绝代价 | 预测裕度减实际裕度的正部，MW；未知/少样本层拒绝比例及额外查询数 | 降低危险乐观误差但查询成本未失控才支持深化；只改善总体均方误差不充分 |

以上均为拟定评价口径。搜索预算、工程容差和显著性水平先用独立试跑确定并冻结，不预填提升百分比。

### 3.7 方向形成的推理链路

- **基础方案：** [P24 · 风电并网静态稳定](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/风电并网系统的静态电压稳定性研究_葛飞飞.pdf>)，PDF pp. 49、51已用裕度信息削减场景；[P26 · 风电断面动态极限](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/静态电压稳定约束下大规模风电送出断面动态极限研究_石子敬.pdf>)，PDF p. 63承认聚类内部异质性 → 有限推断为“裕度近似/距离相似不能自动证明控制事件附近危险工况被保留” → 检验事件差异是否携带额外选点价值 → 三队列外层搜索 → 同预算参考误差与消融。**待证假设是事件差异与危险漏检相关，不是文献已经证明该关联。** [P04 · 最差裕度区间](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Identification_of_the_Worst-Case_Static_Voltage_Stability_Margin_Interval_of_AC_DC_Power_System_Considering_Uncertainty_of_Renewables.pdf>)，PDF pp. 3–4、12限定本方向不能把多RES＋模式切换本身当贡献。
- **深化方案：** 基础只给已发现最小值；[P21 · 功率波动边界直接算法](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/考虑新能源功率波动的静态电压稳定边界直接算法_李安然.pdf>)，PDF pp. 3、5说明区间漏覆盖和求解依赖，[P20 · 在线数据驱动裕度](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Online_Data-Driven_Evaluation_Method_of_Static_Voltage_Stability_Margin_for_AC_DC_Hybrid_Power_Systems_Considering_Uncertainty_of_Renewable_Energy.pdf>)，PDF pp. 8–9、16显示代理标签/更新的条件性 → 有限推断为“平均预测好不等于未发现危险少” → 独立审计、事件层乐观误差校准和拒绝外推 → 验证遗漏概率质量与成本。**待证的是反馈的效率增益；有限样本统计结论只在列明独立抽样条件下成立。**

### 3.8 本方向小结：基础成果与深化增量

基础论文回答“同样花费CPF计算，事件变化信息能否帮助更可靠地找到危险组合”；深化增加“尚未发现的危险区域在指定分布下有多大，以及何时必须拒绝乐观预测”。这条路线最贴合既有内核外层开发和30天成文目标。最大风险是事件信息没有额外搜索价值，或审计成本抵消节省；它不以全局最优证明、动态振荡预测或内核重写为前提。

## 4. 方向二：多场站出力重新分配时，LVRT阈值预警的适用性与边界替换诊断

### 4.1 解决的具体问题

在不同场站有功独立变化、网络和控制参数固定时，**仅依据一个场站接近LVRT阈值或该场站单独增长得到的极限，是否会错误排序系统风险；结合其他场站的无功余量与先后事件，能否识别这种误判何时发生？**

具体构造两组工况：被评估场站距LVRT进入阈值几乎相同，但另一个场站的有功及无功备用不同。一组进入LVRT后可以恢复稳定，另一组出现重复进退或由其他场站先触限。需要诊断的不是“有没有LVRT诱导振荡”这一已知现象，而是**单站风险结论向多场站变化外推的条件，以及主导限制为何换到另一个事件/场站**。

本方向是解释和诊断路线，用预先设计的成对工况与局部扫描即可完成，不需要先实现方向一的最危险点搜索。基础阶段给有限模型上的风险适用性规则，不从静态CPF直接计算振荡幅值或阻尼。

### 4.2 现有工作的局限性

- [P25 · PMU在线评估](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/基于PMU数据的新能源场站静态电压稳定在线评估_孔贺.pdf>)，PDF pp. 60、64、72–75：已研究无故障高出力下LVRT诱导非光滑分岔（HLINB），区分它与SNB，并考虑其他场站无功控制/约束；不能把“首次识别HLINB”或“计及无功上限求极限”重提为贡献。**作者明确假设**在待评场站极限计算中，其他风场有功不变（PDF p. 75）。这支持检验多站独立变化对该条件化结论的适用性，而不是断言多场站研究为空白。
- [P25 · PMU在线评估](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/基于PMU数据的新能源场站静态电压稳定在线评估_孔贺.pdf>)，PDF p. 82作者指出特定算例过程分析仍缺数学机理；PDF p. 114又说明采用简化LVRT、未纳入Crowbar等模型。前者支持有条件的解释性深化；后者提示建模边界，但本课题不以增建Crowbar或重写变流器内核来填补它。
- [P17 · 短路故障LVRT静态稳定](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Research on Static Voltage Stability During Low-voltage Ride-through Under Short-circuit Fault Conditions in Renewable Energy Integrated Power Grids.pdf>)，PDF pp. 3、11–12：处理故障后固定电流角下LVRT静稳，多源算例增加一个DG电流、其他DG固定；作者将不同控制策略留待后续。它不能直接证实正常运行/恢复过程的多站进退动态判据。
- [P07 · 自适应LVRT设置](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/A_Scalable_Method_of_Adaptive_LVRT_Settings_Adjustment_for_Voltage_Security_Enhancement_in_Power_Systems_With_High_Renewable_Penetration.pdf>)，PDF pp. 3、8研究最终恒定LVRT阈值触发的脱网和事件顺序；[P15 · Krylov–Arnoldi框架](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Jacobian-Free_Krylov-Arnoldi_Framework_for_Static_Voltage_Stability_Estimation_of_Power_Systems_With_100_Renewable_Energy.pdf>)，PDF p. 3指出限流切换可能先于鞍点决定极限。二者说明“最早触发阈值”“最先到SNB”“首次不能保持稳定”不是一个量；事件顺序本身也已有研究。

归纳：候选缺口是“多站有功变化导致原本条件化的阈值风险预警失效/迁移，如何用可复核的条件诊断”；不是重新证明阈值切换会引发振荡。

### 4.3 基础方案：可独立成文的研究闭环

建立一种**配对工况诊断**：有意让目标场站的表面预警量相近，改变其他场站出力，然后检查时域结局是否一致；再用少量可解释的系统状态量指出何时单站预警可用、何时必须转交联合评估。与画更多波形相比，新增方法在于配对工况设计、边界类型标签和可拒绝判定的适用性规则。对标30天内基础会议稿，所有比较均使用同一既有CPF与时域模型。

1. **输入与研究边界。** 使用已有2–3新能源场站系统、各站0至额定有功范围、固定功率平衡和LVRT参数。CPF中新能源有功保持各自给定值。先以慢速负荷增长/无故障高出力运行条件定义主任务；不把短路故障中的稳态电流指标混成同一评价量。时域输入采用同一加载/扰动协议，固定初始控制模式与历史。相同状态但不同历史不混成一类。
2. **关键方法与操作步骤。** 用规则网格或拉丁超立方生成试验库，无需方向一。对每个目标站，用相邻组合插值后再真实求解，形成“相近目标站阈值距离、不同其他站出力”的配对样本；控制其他已知因素，报告无法匹配的工况。记录目标站阈值距离、其他站最小无功备用、首两个事件之间的负荷增量、事件发生站点。用已有Simulink施加统一的小增量/缓升协议，标出稳定恢复、持续反复切换、静态可行性丧失和未解决四类结果。再拟合一个浅层、可解释、带拒绝区的分层规则：先判断无功备用/事件间隔是否足以支持单站预警，再作风险判断；资料稀少和两事件近乎同时触发的样本暂不自动分类。
3. **输出与待检验结论。** 输出导致“同阈值距离、不同结局”的最小配对反例、外部工况使主导边界换站/换类型的条件表、规则适用区和拒绝区。假设H3：其他站无功备用与事件间隔能解释一部分单站阈值误报/漏报，且在未参与规则设计的出力区域上仍有效。如果匹配后结局基本一致，或增加这些量没有改善，H3不成立；不能把“多几个变量的分类器”当机制结论。
4. **最低必要验证。** 至少比较单站独立增长、两站出力同时但非同比变化、另一个站无功触限先后改变三类试验；保留未出现振荡的阴性对照。按完整出力区域/事件组合留出测试，不能把一对样本拆进训练和测试制造泛化。RTLAB核对至少一个判别正确配对和一个接近拒绝区的配对；全基础阶段必须有时域标签，不能把必要动态验证推迟到深化。

改变其他场站有功时，平衡机响应和网络潮流重分配属于干预的一部分，应同步记录；这种配对用于模型诊断，不是对某一物理因素的严格因果隔离证明。

这里“持续反复切换”的观测标签需预先规定稳定等待时间、观察窗、电压波动阈值及最低进退次数，并报告对这些参数的敏感性；有限观察窗无振荡只表示该协议下未观测到，不能证明全局动态稳定。“阈值距离”是当前电压与进入阈值之差，单位pu；“无功备用”是到既有无功限额的余量，单位Mvar或统一标幺；“事件间隔”按同一负荷增长路径的MW差定义，缺第二事件单列而不填无限大。遇LVRT退出只使用已确认的时域/内核功能；动态退出不自动等价于静态分支存在。

### 4.4 深化方案：新增问题与实质贡献

基础规则能指出哪里容易误判，却不能解释重复切换是衰减、维持还是把系统带离可行区域。深化研究**多场站切换怎样改变一次“进入—退出—再进入”后的状态，何时主导事件发生替换**。用已有时域模型的状态采样，在外层建立局部切换返回映射：从一个进入事件截面出发，观察到下一次同类进入截面时系统状态变成什么。它描述一次完整切换循环的净效果，而不是只比较电压峰值。

明确闭合状态是关键：映射输入须包含现有模型中决定后续演化的控制器积分状态、滤波状态、当前离散模式及必要的网络状态；有计时/延迟逻辑时还要保留相应记忆。只有电压峰值或CPF代数状态不足以保证Markov闭合。若现有模型能直接导出这些状态，采用有限扰动/多次调用估计局部映射及其线性化；这都是**现有模型外层采样和分析**，不增建变流器微分内核。不满足状态可观测/可导出条件时，不承诺该深化理论成立。

具体构造时，先固定工况参数并选定某站、某触发方向的横截事件截面，用同一事件对齐周期相位；在已验证的周期固定点附近，对满足代数一致性约束的独立动态坐标施加小扰动，记录下一次返回状态，以有限差分估计局部Jacobian（状态映射的导数矩阵）。将扰动步长减半并比较估计结果，另用未参与辨识的扰动验证。未返回、模式改变或事件顺序改变的轨迹不纳入同一局部线性化，分别报告拒绝或边界替换。

| 对比项 | 基础方案已做 | 深化方案新增 | 新增结论及验证方式 |
|---|---|---|---|
| 研究问题与适用边界 | 哪些多站组合让单站阈值预警失效 | 固定局部事件序列下，切换循环为何吸引/排斥；何时另一个站先触发而替换该循环 | 在近邻出力扰动下检验循环状态误差和主导事件变化位置 |
| 模型、算法或理论分析 | 配对反例与带拒绝区的诊断规则 | 基于闭合时域状态的局部返回映射、有限扰动估计；比较相邻站的下一事件触发顺序；在顺序改变边界处分段处理 | 独立初值扰动检验映射闭合性与重复预测误差；跨事件边界不强用同一线性化 |
| 能解释或保证的性质 | 经验诊断适用区 | 光滑局部映射且横截触发等条件下，循环固定点的局部吸引/排斥及失效边界；不保证全局吸引域 | 用映射Jacobian谱半径与真实周期扰动衰减/增长比较；近同时事件区允许不作确定判断 |

- **成立前提与失效条件。** 存在可重复的返回截面和完整周期、状态闭合、触发横截而非擦边、所考察小邻域事件顺序固定、参数在周期内近似不变。谱半径小于1只在这些局部条件下支持周期轨道吸引；不等同原稳态运行点安全，更不证明无振荡。未返回截面、事件近同时触发、擦边、明显延迟记忆缺失或隐藏控制状态导致映射多值，均使这一路局部分析失效，转为“未适用”并保留时域证据。
- **贡献边界。** 拟新增的是多站出力变化引发的“事件顺序替换—循环收缩性质变化”的可检验解释，以及据此修正基础诊断的拒绝区。标准返回映射或谱半径判据本身不是原创；只有得到跨工况可复核的新条件/边界规律，才有深化价值。不把“再跑一次RTLAB”算作增量。
- **失败时可保留的成果。** 若无法导出闭合状态或不存在稳定返回周期，则不新建动态内核凑理论；保留基础配对诊断及误判条件，并把可观测性不足列为深化停止条件。即使返回映射失败，基础论文仍可独立回答预警适用性问题，前提是基础对照确有新证据。
- **面向更高水平期刊仍需补齐。** 要证明局部映射所需状态和假设、提供事件替换条件的解析或半解析解释、留出模型/参数上的独立验证，并说明对输配电运行预警的具体价值。可将IEEE Transactions on Power Delivery作为深化目标，但当前证据不等于达到其录用标准。

### 4.5 所需仿真平台、模型与预期难度

| 项 | 基础方案所需 | 深化方案额外所需 |
|---|---|---|
| 平台与测试系统 | 既有MATLAB切换CPF，2–3场站Simulink模型，RTLAB代表性复核 | 相同模型的全状态采样/可重复初始化、批量扰动试验，不新增动态设备模型 |
| 可复用代码及与内核的关系 | **直接复用CPF和时域模型**；试验组织、配对和判别在外层 | **直接复用两个内核**；返回截面检测、映射辨识与局部分析在外层 |
| 需新增模型或模块 | 成对工况生成、动态结局标签、浅层规则/拒绝区及留出测试 | 闭合状态接口、截面事件采样、有限扰动映射估计、事件替换条件分析 |
| 数据、设备与其他资源 | 控制阈值、时域观察协议和现有可运行模型；无需PMU现场数据 | 能读取所需内部状态、复位初值；若接口不具备则不进入该深化 |
| 周期估计及依据 | 30天：第1周固定协议/匹配工况；第2周配对扫描；第3周规则与留出验证；第4周硬件复核及成文 | 预计另加8–12周作为规划量级，状态导出和局部理论的可行性决定实际周期 |
| 难度评级与理由 | 中高；配对控制与动态标签质量比搜索计算更关键 | 高；混杂切换、状态闭合、擦边与顺序改变会破坏局部映射 |
| 主要风险与应对 | 如果没有稳健反例或规则不能外推，明确限定适用性，不靠更多波形填贡献 | 不能获得闭合状态或局部周期时停止理论延伸，保留基础诊断，不转向重写内核 |

研究简报声明已验证进退LVRT现象，因此按复用已有模型规划；仅实施前核对运行版本、可观测量和事件标签含义，不做底层开发项目。若静态CPF没有退出功能，基础诊断仍可使用真实时域退出记录；不能用静态假想退出分支补足数据。

### 4.6 基线方法与可量化指标

| 层次 | 对照组或消融设计 | 隔离的因素 / 回答的问题 |
|---|---|---|
| 基础 | 单站阈值距离；固定其他站有功的逐站极限；单独SNB裕度排序 | 单站指标在独立多站变化时何时失效；对应[P25 · PMU在线评估](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/基于PMU数据的新能源场站静态电压稳定在线评估_孔贺.pdf>)，PDF pp. 60、75的条件范围，但不冒称直接复现其SOCP算法 |
| 基础 | 仅加无功备用、仅加事件间隔、两者皆加；同容量但不同出力分配 | 系统耦合量是否有独立解释价值，还是仅因输入变量更多 |
| 基础 | 不带拒绝区与带拒绝区；整块出力区域留出 | 误判下降是否只因拒绝大量样本，以及能否外推 |
| 深化 | 本方向基础诊断；只看电压峰值的非闭合映射；单站状态映射；完整多站状态映射 | 状态闭合和多站耦合对周期预测是否必要 |
| 深化 | 固定事件顺序的单一映射与分段顺序映射；状态扰动独立验证 | 边界替换机制能否解释原模型失效，而非单纯增加拟合自由度 |

| 层次 | 指标 | 定义、计算方式与单位 | 支持 / 否定假设的判据及依据 |
|---|---|---|---|
| 基础 | 配对结局不一致率 | 匹配容差内，单站预警量近似相同而时域类别不同的对数/有效配对数 | 存在可复现差异说明仅用该单站量不充分；无差异不能支持预设失效叙事 |
| 基础 | 漏报、误报与覆盖率 | 漏报：被判安全的风险样本/全部风险样本；误报：安全样本被判风险的比例；覆盖率：给出判定样本/全部样本 | 统一覆盖率或同时报告拒绝率时，留出集改善才支持H3；不能靠全拒绝达零漏报 |
| 基础 | 主导边界/场站识别 | 对明确标签样本，预测首次有效限制类型和场站与时域/CPF证据一致的比例；模糊样本单列 | 不能只做到风险二分类；应定位何种外部事件让单站结论失效 |
| 深化 | 映射闭合与预测误差 | 同一所选状态邻域不同历史的返回状态差；独立初始扰动下一周期状态预测误差，按状态基值归一化 | 历史造成不可忽略多值则闭合假设失败，不能继续解释谱半径 |
| 深化 | 局部吸引判定及边界误差 | 谱半径相对1的位置与周期扰动衰减/增长符号比较；事件替换出力位置误差以额定功率百分比报告 | 只在固定序列、横截和闭合状态验证通过的邻域作结论；擦边附近失效须主动揭示 |

这些是试验前固定的评价标准，不是已有精度结论。时域观测窗、匹配容差、拒绝阈值必须通过独立预实验定下，不能在测试集上反复调至成功。

### 4.7 方向形成的推理链路

- **基础方案：** [P25 · PMU在线评估](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/基于PMU数据的新能源场站静态电压稳定在线评估_孔贺.pdf>)，PDF p. 75明确固定其他风场有功，但PDF pp. 60、64已给HLINB/SNB机制 → 有限推断为“单站条件化判据外推到其他站同时变化需重新检验” → 配对控制目标站阈值距离，改变其他站出力和无功备用 → 用动态结局验证预警是否误判，再提炼可拒绝的适用性规则。[P17 · 短路故障LVRT静态稳定](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Research on Static Voltage Stability During Low-voltage Ride-through Under Short-circuit Fault Conditions in Renewable Energy Integrated Power Grids.pdf>)，PDF pp. 3、11–12和[P07 · 自适应LVRT设置](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/A_Scalable_Method_of_Adaptive_LVRT_Settings_Adjustment_for_Voltage_Security_Enhancement_in_Power_Systems_With_High_Renewable_Penetration.pdf>)，PDF pp. 3、8限定不能把故障稳态/脱网阈值证据直接替代进退振荡。**待证假设是多站变化确有可稳定解释的风险差异。**
- **深化方案：** 基础只观察配对结局，尚不能解释为何循环持续；[P25 · PMU在线评估](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/基于PMU数据的新能源场站静态电压稳定在线评估_孔贺.pdf>)，PDF p. 82明确特定算例过程分析的数学机理不足 → 在已有模型和闭合状态可获得的前提下，研究一次切换循环净作用及事件顺序替换 → 外层返回映射和局部稳定分析 → 独立状态扰动与跨工况边界验证。**证据支持的是深化动机，不证明返回映射必定存在、状态闭合或该研究具有绝对新颖性。**

### 4.8 本方向小结：基础成果与深化增量

基础论文回答“为什么一个场站看起来离阈值同样远，却因其他站出力不同而得到不同风险结论，以及何时可以继续用单站预警”；深化进一步解释“多个场站的切换怎样使循环维持、衰减或被另一个事件替换”。它适合已有时域/RTLAB模型且重视机理解释的条件。最大风险是无法得到可推广的配对规律，或深化缺少闭合状态；该路线不依赖方向一的搜索成果，也不以再证明HLINB或新建变流器内核为目标。

## 5. 两方向的差异与取舍

| 比较项 | 方向一 | 方向二 |
|---|---|---|
| 核心研究问题与主要贡献机制 | 如何分配有限CPF预算以发现低裕度组合；事件差异驱动选点和独立遗漏审计 | 何时单站阈值风险判断在多站变化中失效；配对诊断和切换循环解释 |
| 可独立完成基础论文的依据 | 空间覆盖、事件选点、强基线、数值参考和少量时域复核构成闭环 | 固定试验库、配对反例、适用性规则、留出动态验证构成闭环，无需危险点搜索算法 |
| 基础成果与深化新增结论 | 基础为查询成本—发现质量关系；深化为指定分布下可审计的危险遗漏与乐观误差 | 基础为预警适用区和拒绝区；深化为闭合状态下循环吸引/事件替换的局部条件 |
| 基础可行性与深化风险 | 30天较贴合外层工作；风险是事件队列无增益；深化风险在审计成本和稀有事件 | 30天依赖现成动态模型；风险是匹配/标签和泛化；深化风险在状态闭合与混杂边界 |
| 适用资源与目标层级 | 有批量MATLAB计算最合适；基础CIYCEE 2026，深化TPWRD作为待验证目标 | 有稳定时域模型与可用RTLAB最合适；基础同样CIYCEE 2026，深化同样可瞄准TPWRD但不承诺 |

**独立性。** 两方向共享现有模型、场站数据和事件记录，但研究产物不同。方向一只需其自身数值搜索对照，不需要方向二先推导振荡判据；方向二用预设工况和配对实验，不需要方向一先找到全域最坏点。任一方向单独选择，都不以完成另一条路线作为验收前提。

**取舍与推荐顺序。** 按“30天成文、复用既有CPF、补齐外层组合分析”的优先级，建议先选方向一基础方案；它更直接补齐当前空缺，且工作边界容易控制。若甲方更重视现有RTLAB进退振荡成果和物理解释，并且时域模型标签稳定，则可直接选方向二基础方案。两条深化均需基础结果支持后再投入，不建议30天同时铺开两条路线；方向二更偏机理，方向一更偏可重复方法性能，不能分别当作低配与高配。

## 6. 需要甲方确认的事项

1. **方向选择：** 建议方向一基础优先；若更希望沿已有LVRT进退振荡验证形成分析型论文，选择方向二基础。请选其一作为后续实验设计主线。
2. **推进层次：** 已知目标是30天基础成文，建议先保住所选基础闭环，只同步保存该方向深化所需日志/状态，不同步实现两个深化方案。
3. **评价偏好：** 若选方向一，明确更关注较低最坏裕度的发现还是给定危险阈值的漏检；若选方向二，明确更重视少漏报还是较高自动判定覆盖率。具体数值由独立预实验拟定，不重复询问已知平台与目标刊物。
4. **模型和场景的实施边界：** 确定首先使用哪一个现成算例、站点及额定值；确认各独立出力组合的功率平衡规则与零出力并网状态；方向二额外确认现有时域模型能提供哪些控制状态、模式与进退记录。这里只需功能/运行确认，不要求展开代码审查或重写内核。
5. **目标及额外投入：** 基础目标沿用CIYCEE 2026、深化目标沿用IEEE Transactions on Power Delivery；实际截稿日及投稿范围尚未在本轮核验。若基础结果支持深化，再确认能否接受方向一约6–10周或方向二约8–12周的额外研究投入，这些只是初步规划量级。

请甲方先确认**主选方向与评价偏好**。确认后再制定详细实验方案；本轮交付的是有证据支持的候选研究路线，不是已成立的创新点或已验证算法。

## 7. 证据与附件

下列26篇均用于本报告的覆盖、竞争路线或局限证据判断。页码列为独立审查取证页及本章异常核验定位页，1.1已逐篇定位。完整题名以目标清单为准；绝对链接已逐一检查存在并与身份映射一致。

| 论文ID | 完整题名 | 本地PDF | 本报告引用的物理页码 |
|---|---|---|---|
| P01 | An Extended Continuation Power Flow Method for Static Voltage Stability Assessment of Renewable Power Generation-Penetrated Power Systems | [P01 · 扩展CPF](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/An_Extended_Continuation_Power_Flow_Method_for_Static_Voltage_Stability_Assessment_of_Renewable_Power_Generation-Penetrated_Power_Systems.pdf>) | 4、5 |
| P02 | SVG Configuration Scheme to Enhance Renewable Energy Accommodation Considering Voltage Stability Constraints in Renewable Power Grids | [P02 · SVG配置](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/SVG Configuration Scheme to Enhance Renewable Energy Accommodation Considering Voltage Stability Constraints in Renewable Power Grids.pdf>) | 2、4、5 |
| P03 | A Static Voltage Stability Enhancement Method for Power Systems With a High Proportion of Voltage Source Converters | [P03 · 高比例VSC稳定增强](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/A_Static_Voltage_Stability_Enhancement_Method_for_Power_Systems_With_a_High_Proportion_of_Voltage_Source_Converters.pdf>) | 1、9、12 |
| P04 | Identification of the Worst-Case Static Voltage Stability Margin Interval of AC/DC Power System Considering Uncertainty of Renewables | [P04 · 最差裕度区间](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Identification_of_the_Worst-Case_Static_Voltage_Stability_Margin_Interval_of_AC_DC_Power_System_Considering_Uncertainty_of_Renewables.pdf>) | 3、4、12 |
| P05 | Optimal Enhancement Control of Static Voltage Stability Margin for AC/DC Power System With Renewables Considering Control Mode Switching of DC Converter Stations | [P05 · 模式切换裕度增强](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Optimal_Enhancement_Control_of_Static_Voltage_Stability_Margin_for_AC_DC_Power_System_With_Renewables_Considering_Control_Mode_Switching_of_DC_Converter_Stations.pdf>) | 3、4、10、11 |
| P06 | Power System Voltage Stability Evaluation Considering Renewable Energy With Correlated Variabilities | [P06 · 相关新能源稳定评估](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Power_System_Voltage_Stability_Evaluation_Considering_Renewable_Energy_With_Correlated_Variabilities.pdf>) | 3、6、9 |
| P07 | A Scalable Method of Adaptive LVRT Settings Adjustment for Voltage Security Enhancement in Power Systems With High Renewable Penetration | [P07 · 自适应LVRT设置](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/A_Scalable_Method_of_Adaptive_LVRT_Settings_Adjustment_for_Voltage_Security_Enhancement_in_Power_Systems_With_High_Renewable_Penetration.pdf>) | 3、8 |
| P08 | TPCPF: Three-Phase Continuation Power Flow Tool for Voltage Stability Assessment of Distribution Networks With Distributed Energy Resources | [P08 · 三相TPCPF](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/TPCPF_Three-Phase_Continuation_Power_Flow_Tool_for_Voltage_Stability_Assessment_of_Distribution_Networks_With_Distributed_Energy_Resources.pdf>) | 2、4、5 |
| P09 | Renewable Power Hosting Capacity Assessment Considering L-Index for Static Voltage Stability | [P09 · L指数承载力](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Renewable_Power_Hosting_Capacity_Assessment_Considering_L-Index_for_Static_Voltage_Stability.pdf>) | 3、4、5 |
| P10 | Static Voltage Stability Analysis of Renewable Energy Multi-Infeed Systems Based on Margin Index | [P10 · 多馈入裕度指标](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Static_Voltage_Stability_Analysis_of_Renewable_Energy_Multi-Infeed_Systems_Based_on_Margin_Index.pdf>) | 2、5、8 |
| P11 | Static Voltage Stability Based Maximum Integration Ratio of Distributed Renewable Energy in Distribution Power System | [P11 · 配电网最大接入比](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Static_Voltage_Stability_Based_Maximum_Integration_Ratio_of_Distributed_Renewable_Energy_in_Distribution_Power_System.pdf>) | 2、3、4 |
| P12 | Probabilistic Static Voltage Stability Assessment for Distribution Network Considering Correlated Renewable Energy | [P12 · 相关新能源概率评估](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Probabilistic_Static_Voltage_Stability_Assessment_for_Distribution_Network_Considering_Correlated_Renewable_Energy.pdf>) | 3、4、5 |
| P13 | Static Voltage Stability Analysis and Control Strategy of Distribution Network with High Proportion Distributed PV Generation During Fault | [P13 · 故障期分布式光伏](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Static_Voltage_Stability_Analysis_and_Control_Strategy_of_Distribution_Network_with_High_Proportion_Distributed_PV_Generation_During_Fault.pdf>) | 1、2、3、4 |
| P14 | Static Voltage Stability Criterion of Renewable Energy Sources based on Power Flow Analysis | [P14 · 潮流静态稳定判据](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Static_Voltage_Stability_Criterion_of_Renewable_Energy_Sources_based_on_Power_Flow_Analysis.pdf>) | 1、2、4、5 |
| P15 | Jacobian-Free Krylov-Arnoldi Framework for Static Voltage Stability Estimation of Power Systems With 100% Renewable Energy | [P15 · Krylov–Arnoldi框架](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Jacobian-Free_Krylov-Arnoldi_Framework_for_Static_Voltage_Stability_Estimation_of_Power_Systems_With_100_Renewable_Energy.pdf>) | 1、2、3、11、12 |
| P16 | Static Voltage Stability Analysis of Large Scale Renewable Energy Delivered via Multi-Voltage-Level Transmission Sections | [P16 · 多电压等级送出断面](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Static_Voltage_Stability_Analysis_of_Large_Scale_Renewable_Energy_Delivered_via_Multi-Voltage-Level_Transmission_Sections.pdf>) | 1、2、4、5 |
| P17 | Research on Static Voltage Stability During Low-voltage Ride-through Under Short-circuit Fault Conditions in Renewable Energy Integrated Power Grids | [P17 · 短路故障LVRT静态稳定](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Research on Static Voltage Stability During Low-voltage Ride-through Under Short-circuit Fault Conditions in Renewable Energy Integrated Power Grids.pdf>) | 1、2、3、11、12 |
| P18 | Research on Coordinated Active and Reactive Power Control of VSC-HVDC Connected Renewable Energy System for Enhancing Static Voltage Stability | [P18 · VSC-HVDC协调控制](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Research_on_Coordinated_Active_and_Reactive_Power_Control_of_VSC-HVDC_Connected_Renewable_Energy_System_for_Enhancing_Static_Voltage_Stability.pdf>) | 1、2、5、6 |
| P19 | Study of Static Voltage Stability Region Considering Integration of Renewable Energy Through VSC-HVDC System | [P19 · VSC-HVDC稳定域](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Study_of_Static_Voltage_Stability_Region_Considering_Integration_of_Renewable_Energy_Through_VSC-HVDC_System.pdf>) | 1、2、4、5 |
| P20 | Online Data-Driven Evaluation Method of Static Voltage Stability Margin for AC/DC Hybrid Power Systems Considering Uncertainty of Renewable Energy | [P20 · 在线数据驱动裕度](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Online_Data-Driven_Evaluation_Method_of_Static_Voltage_Stability_Margin_for_AC_DC_Hybrid_Power_Systems_Considering_Uncertainty_of_Renewable_Energy.pdf>) | 1、2、8、9、16、17、18 |
| P21 | 考虑新能源功率波动的静态电压稳定边界直接算法 | [P21 · 功率波动边界直接算法](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/考虑新能源功率波动的静态电压稳定边界直接算法_李安然.pdf>) | 1、2、3、4、5、6 |
| P22 | 考虑静态电压稳定的新能源基地构网型场站与无功源优化配置方法 | [P22 · 构网场站与无功源配置](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/考虑静态电压稳定的新能源基地构网型场站与无功源优化配置方法_赵冬梅.pdf>) | 1、2、3、4、9、12 |
| P23 | 计及静态电压稳定裕度的电力系统新能源承载能力评估方法 | [P23 · 新能源承载能力](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/计及静态电压稳定裕度的电力系统新能源承载能力评估方法_陈沁昊.pdf>) | 1、2、3、7、9、10 |
| P24 | 风电并网系统的静态电压稳定性研究 | [P24 · 风电并网静态稳定](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/风电并网系统的静态电压稳定性研究_葛飞飞.pdf>) | 46、49、51、58 |
| P25 | 基于PMU数据的新能源场站静态电压稳定在线评估 | [P25 · PMU在线评估](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/基于PMU数据的新能源场站静态电压稳定在线评估_孔贺.pdf>) | 60、64、72、73、74、75、82、113、114、115 |
| P26 | 静态电压稳定约束下大规模风电送出断面动态极限研究 | [P26 · 风电断面动态极限](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/静态电压稳定约束下大规模风电送出断面动态极限研究_石子敬.pdf>) | 9、10、13、14、27、28、37、43、62、63、64 |

- 目标清单与纳入/排除决定：[_targets.json](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/paper-notes/_targets.json>)。
- 语料对账与清点：[_inventory.json](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/paper-notes/_inventory.json>)。
- 竞争路线覆盖与Gate：[_coverage.md](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/paper-notes/_coverage.md>)。
- 本轮章节索引和逐页原文的精确入口：[_extraction_summary.json](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/paper-notes/_extraction_summary.json>)。
- 独立核验、SHA-256、页/offset、引文与处置：[_review.json](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/paper-notes/_review.json>)。
- 主agent关键证据抽查：[_spotchecks.json](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/paper-notes/_spotchecks.json>)。
- 需补充的纳入目标全文/文本：无；无已确认不可读而待补的关键页，不要求OCR或排除论文补件。
- 待核验项与证据缺口：未读页、全部公式和实验复现不在本轮认证范围；P09/P18冲突数值不用；历史local排除所留下的其他动态机理不能借用为本轮全文证据。无仅摘要目标、无用户豁免。后续选定方向时仅围绕实际需要补核验，不把这些限制写成已解决。