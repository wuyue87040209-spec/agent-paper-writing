# P01–P12 独立范围核验与局限性矩阵

核验者：Codex `/root/review_a`；日期：2026-10-11。仅当前纳入清单与最终 `_extraction_summary.json` 指定的本地PDF；未检索或引入历史库。逐篇文件身份、SHA-256、实际阅读范围、38条逐字引文及页内字符偏移记录在 `_review_a.json`。哈希与引文对最终保存的 `.pages.json` 已逐条复核。

结论：P01–P12均达到“已核验该范围”；没有阻断所述自然语言判断的未解决问题。**不等于全文全部阅读，不认证未读公式推导、全部表格数值或算法最优性。** 以下“候选缺口”是基于已读范围的研究者判断；只有“作者局限/展望”列表示作者明示。

| ID／来源 | 方法、模式与约束 | 维度及验证 | 作者局限／展望（物理页） | 本项目可用候选缺口与适用性（研究者判断） |
|---|---|---|---|---|
| P01／IEEE T-CAS II 2024 | 扩展CPF，显式更新CVRPG控制模式，以扩展Jacobian判断极限 | New England系统，Bus15负荷增长、控制系数对比；PSCAD验证（p4） | 控制参数优化为未来工作（p5） | 切换CPF已存在，不能包装成新贡献；可复用内核，外围检索多个独立RES出力组合。已读算例不能支持全箱域最坏搜索主张。 |
| P02／IEEE T-CAS II 2025 | SVG选址定容、MRSCR约束、典型新能源场景加权收益 | 全年出力k-means典型场景，SG118，MATLAB/CPLEX（p4） | SVG成本与设备间相互影响（p5） | 规划和新能源场景变化已有；MRSCR与故障后电压上升限制相关（p2），不能作为切换CPF/SNB证明。可作外部工程对照。 |
| P03／IEEE TPWRS 2025 | VSC电压控制与dq电流限值、达到饱和后的电流源行为 | 多VSC、扩展IEEE39；同步机/VSC有功同比增长、负荷固定功率因数（p9） | 未计及VSC资源输出间歇变化、离散无功补偿设备（p12）；暂态故障问题不在范围（p1） | 对独立出力组合外层搜索提供较直接需求证据；不可推断它没有多VSC或限流处理。适合基础方向对照。 |
| P04／CSEE JPES 2024 | 多RES区间与负荷增长方向不确定性，最差裕度区间；SG无功限值、LCC及VSC模式切换 | IEEE39及实际8733节点；大型系统模式切换示例（p12） | 本文计算最差裕度区间，未来研究运行参数调整与增强控制（p12–13） | **已有“不确定多RES＋模式切换＋最坏裕度”组合。** RES自身恒功率因数（p3）；直流站模式不等于新能源LVRT进入/退出。只有明确限定RES控制事件、评价口径及新证据后才可能区分；不能以简单拼接立项。 |
| P05／IEEE TIA 2025 | 三角凸松弛、IR-LASSO/UaM/KKT用于裕度增强；RES恒功率因数、DC默认模式序列 | IEEE39三RES，各自区间：Bus9为600–1000 MW，Bus1/18为100–300 MW（p10） | 仅正常运行预防控制；多N−1条件留待后续（p11） | 最坏裕度驱动控制已有直接竞争；应避开“首次多RES”叙事。可对比其固定功率因数/默认DC序列与已有内核中实际可支持的RES控制事件。N−1并非本项目基础阶段必选。 |
| P06／IEEE TPWRS 2018 | Gaussian Copula相关输入、SRSM、全局灵敏度用于裕度概率与变量贡献 | IEEE9/118，GSA与局部灵敏度比较（p6） | 稀疏自适应SRSM、黑箱应用（p9） | 概率重要性排序不能代替最坏点保证。可借鉴相关输入与降维筛选；概率和最坏值两种口径必须分开。 |
| P07／IEEE TSTE 2022 | LVRT曲线最终恒定阈值触发RES脱网，二进制在线状态、PV曲线跳转 | IEEE14记录6次脱网与1次无功限值事件；IEEE118/500验证 | 明确仅调整LVRT曲线最终恒定部分（p3，范围限定） | 事件先后顺序与曲线跳转已有；不能宣称事件序列首次用于稳定性分析。它不是RES内部LVRT进入/退出控制振荡模型；若本项目研究该区别，须由已有内核实际能力支持。 |
| P08／IEEE TIA 2021 | 三相电流注入CPF，已有自适应步长、PV-PQ切换、鼻点判据 | 固定发电、λ负荷增长；IEEE13、船舶18、CIGRE13、136节点 | 已读结论主要总结贡献，未定位可直接引用的未来工作 | 数值推进策略本身不可当新颖点。已读范围未展示独立RES箱域最坏搜索；可作CPF求解技术背景，不宜改写内核主攻。 |
| P09／IEEE APPEEC 2024 | L-index约束新能源承载力，原始对偶内点法 | IEEE30，一个PV与一个风电场，各受0至最大值约束 | 已读结论未提供明确未来方向 | 可作静态指标承载力对照，不能视作路径切换/SNB证据。p4场景文字与表III数值对应冲突，禁止引用其数值性能。 |
| P10／IEEE CIEEC 2024 | Thevenin等值及源侧静态裕度指标，恒功率因数RES | 改进IEEE39，风电Bus32/33/34；逐站增长、其他站有功固定、负荷或SG平衡（p5） | 指标依赖等值参数精度和等值保持电压功率灵敏度假设（p8） | 逐站扫描不能穷尽多站组合；可为基础方向提供便宜但有假设的对照。不得称其未研究多馈入。 |
| P11／IEEE ICCEPE 2024 | 径向配电网过电压约束接入分配；MPPT且Q=0假设（p2） | 五DER算例与分配规则（p3） | 无功出力、环网适用性（p4） | 属过电压hosting口径，不直接解决低电压SNB最坏边界；仅作范围区分背景。公式字符损坏，不采用其数学或数值主张。 |
| P12／ACPEE 2020 | 相关新能源、Sobol QMC外层样本逐次调用CPF，得到概率裕度分布 | 文中IEEE33，四DG含两风一PV一燃气；QMC与SRS对比 | 作者说明风电比例小使相关性影响较小（p4） | **外层采样调用CPF已有**，不能作为贡献本身。可作为随机/准蒙特卡洛基线；所示概率精度不构成最坏组合或全局最优保证。 |

## 必须保留的竞争边界

1. 基础方向可侧重“复用已有新能源切换CPF内核，构建独立有功组合的有限预算最坏情景搜索与可信评估”；需清楚注明域、平衡规则、内核状态和基线，不能声称发现此前不存在的多RES最坏裕度问题。
2. 深化方向若用事件信息指导外层搜索，须越过P07已有事件顺序、P04/P05已有模式与最坏裕度组合的竞争；事件信息带来的搜索效率/漏检率改善必须实证，不能把事件标签自身当创新。
3. 减少内核代码审查与改造：遵从简报直接复用既有内核，但所声称的控制事件类型仍需由使用者确认的功能边界和运行结果支撑。公开文献里“模式切换”含义不同，不能混称。

## 机器候选边界纠正与文本质量

- P07引言机器止于p2 offset 5406，实际应延至 `II. I MPACTS` 之前；已更正review侧边界并补读。
- P10每页含乱码字码层与可读英文重复层。按可读层重建摘要/引言/结论边界：摘要p1 6952–8043；引言p1 8166–12736 + p2 5588–6501；结论p7 6691–7177 + p8 3871–4535。p2/p8另经PDF渲染视觉核对；无须OCR，不把乱码/参考文献计入证据。
- P04公式私用字符、P08部分公式字流、P11公式损坏及P06/P12图形/公式字流均不承载本次关键断言；明确限制到清晰正文。P04最强竞争点取p3–4、12清晰文字，P05取p3–4、10–11。
- P09 p4场景标签与表III矛盾保留为原文内部不一致，未擅自修复或采用数值。
- P12首页题名与作者核验通过，但提取未找到DOI；没有伪称DOI已核验。
- 原机器索引保持pending，不直接改成全文已核验；详细review文件记录人的范围核验。

## 本地原文定位

- P01：[本地PDF](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/An_Extended_Continuation_Power_Flow_Method_for_Static_Voltage_Stability_Assessment_of_Renewable_Power_Generation-Penetrated_Power_Systems.pdf>)；主要引文物理页：4, 5。
- P02：[本地PDF](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/SVG Configuration Scheme to Enhance Renewable Energy Accommodation Considering Voltage Stability Constraints in Renewable Power Grids.pdf>)；主要引文物理页：2, 4, 5。
- P03：[本地PDF](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/A_Static_Voltage_Stability_Enhancement_Method_for_Power_Systems_With_a_High_Proportion_of_Voltage_Source_Converters.pdf>)；主要引文物理页：1, 9, 12。
- P04：[本地PDF](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Identification_of_the_Worst-Case_Static_Voltage_Stability_Margin_Interval_of_AC_DC_Power_System_Considering_Uncertainty_of_Renewables.pdf>)；主要引文物理页：3, 4, 12。
- P05：[本地PDF](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Optimal_Enhancement_Control_of_Static_Voltage_Stability_Margin_for_AC_DC_Power_System_With_Renewables_Considering_Control_Mode_Switching_of_DC_Converter_Stations.pdf>)；主要引文物理页：3, 4, 10, 11。
- P06：[本地PDF](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Power_System_Voltage_Stability_Evaluation_Considering_Renewable_Energy_With_Correlated_Variabilities.pdf>)；主要引文物理页：3, 6, 9。
- P07：[本地PDF](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/A_Scalable_Method_of_Adaptive_LVRT_Settings_Adjustment_for_Voltage_Security_Enhancement_in_Power_Systems_With_High_Renewable_Penetration.pdf>)；主要引文物理页：3, 8。
- P08：[本地PDF](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/TPCPF_Three-Phase_Continuation_Power_Flow_Tool_for_Voltage_Stability_Assessment_of_Distribution_Networks_With_Distributed_Energy_Resources.pdf>)；主要引文物理页：2, 4, 5。
- P09：[本地PDF](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Renewable_Power_Hosting_Capacity_Assessment_Considering_L-Index_for_Static_Voltage_Stability.pdf>)；主要引文物理页：3, 5。
- P10：[本地PDF](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Static_Voltage_Stability_Analysis_of_Renewable_Energy_Multi-Infeed_Systems_Based_on_Margin_Index.pdf>)；主要引文物理页：2, 5, 8。
- P11：[本地PDF](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Static_Voltage_Stability_Based_Maximum_Integration_Ratio_of_Distributed_Renewable_Energy_in_Distribution_Power_System.pdf>)；主要引文物理页：2, 3, 4。
- P12：[本地PDF](</Users/huangxm/Desktop/Mr.Leo/Project/paper-writing/idea-discovery/fulltext-pdfs/Probabilistic_Static_Voltage_Stability_Assessment_for_Distribution_Network_Considering_Correlated_Renewable_Energy.pdf>)；主要引文物理页：3, 4, 5。
