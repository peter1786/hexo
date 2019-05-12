---
title: GC日志分析
tags:
  - java
  - jvm
categories:
  - java
toc: false
date: 2018-09-12 16:08:45
---

# ParNew


# CMS


CMS的设计目标是避免在老年代垃圾收集时出现长时间的卡顿。主要通过两种手段来达成此目标。
> 
	第一, 不对老年代进行整理, 而是使用空闲列表(free-lists)来管理内存空间的回收。
	第二, 在 mark-and-sweep (标记-清除) 阶段的大部分工作和应用线程一起并发执行。
也就是说, 在这些阶段并没有明显的应用线程暂停。但值得注意的是, 它仍然和应用线程争抢CPU时间。默认情况下, CMS 使用的并发线程数等于CPU内核数的 1/4。

通过以下选项来指定CMS垃圾收集器:

``` 
 -XX:+UseConcMarkSweepGC
```

如果服务器是多核CPU，并且主要调优目标是降低延迟, 那么使用CMS是个很明智的选择. 减少每一次GC停顿的时间,会直接影响到终端用户对系统的体验, 用户会认为系统非常灵敏。 因为多数时候都有部分CPU资源被GC消耗, 所以在CPU资源受限的情况下,CMS会比并行GC的吞吐量差一些。

日志：
```
2015-05-26T16:23:07.321-0200: 64.425: [GC (CMS Initial Mark) [1 CMS-initial-mark: 10812086K(11901376K)] 10887844K(12514816K), 0.0001997 secs] [Times: user=0.00 sys=0.00, real=0.00 secs]
2015-05-26T16:23:07.321-0200: 64.425: [CMS-concurrent-mark-start]
2015-05-26T16:23:07.357-0200: 64.460: [CMS-concurrent-mark: 0.035/0.035 secs] [Times: user=0.07 sys=0.00, real=0.03 secs]
2015-05-26T16:23:07.357-0200: 64.460: [CMS-concurrent-preclean-start]
2015-05-26T16:23:07.373-0200: 64.476: [CMS-concurrent-preclean: 0.016/0.016 secs] [Times: user=0.02 sys=0.00, real=0.02 secs]
2015-05-26T16:23:07.373-0200: 64.476: [CMS-concurrent-abortable-preclean-start]
2015-05-26T16:23:08.446-0200: 65.550: [CMS-concurrent-abortable-preclean: 0.167/1.074 secs] [Times: user=0.20 sys=0.00, real=1.07 secs]
2015-05-26T16:23:08.447-0200: 65.550: [GC (CMS Final Remark) [YG occupancy: 387920 K (613440 K)]65.550: [Rescan (parallel) , 0.0085125 secs]65.559: [weak refs processing, 0.0000243 secs]65.559: [class unloading, 0.0013120 secs]65.560: [scrub symbol table, 0.0008345 secs]65.561: [scrub string table, 0.0001759 secs][1 CMS-remark: 10812086K(11901376K)] 11200006K(12514816K), 0.0110730 secs] [Times: user=0.06 sys=0.00, real=0.01 secs]
2015-05-26T16:23:08.458-0200: 65.561: [CMS-concurrent-sweep-start]
2015-05-26T16:23:08.485-0200: 65.588: [CMS-concurrent-sweep: 0.027/0.027 secs] [Times: user=0.03 sys=0.00, real=0.03 secs]
2015-05-26T16:23:08.485-0200: 65.589: [CMS-concurrent-reset-start]
2015-05-26T16:23:08.497-0200: 65.601: [CMS-concurrent-reset: 0.012/0.012 secs] [Times: user=0.01 sys=0.00, real=0.01 secs]

```
**注：** 在实际情况下, 进行老年代的并发回收时, 可能会伴随着多次年轻代的小型GC. 在这种情况下, 大型GC的日志中就会掺杂着多次小型GC事件


CMS收集的执行过程是：初始标记(CMS-initial-mark) -> 并发标记(CMS-concurrent-mark) -->并发预清理(CMS-concurrent-preclean)-->可控预清理(CMS-concurrent-abortable-preclean)-> 重新标记(CMS-remark) -> 并发清除(CMS-concurrent-sweep) ->并发重设状态等待下次CMS的触发(CMS-concurrent-reset)

**阶段一：Initial Mark(初始标记)**。 此阶段的目标是标记老年代中所有存活的对象, 包括 GC ROOR 的直接引用, 以及由年轻代中存活对象所引用的对象。 后者也非常重要, 因为老年代是独立进行回收的。
![04_06_g106.png](/images/2019/04/13/a6666530-5dab-11e9-94d6-37a08b4dce14.png)

<div class="code-line-wrap">
<p class="code-line"><span class="node">2015-05-26T16:23:07.321-0200: 64.42<sup>1</sup></span>: [GC (<span class="node">CMS Initial Mark<sup>2</sup></span>[1 CMS-initial-mark: <span class="node">10812086K<sup>3</sup></span><span class="node">(11901376K)<sup>4</sup></span>] <span class="node">10887844K<sup>5</sup></span><span class="node">(12514816K)<sup>6</sup></span>, <span class="node">0.0001997 secs] [Times: user=0.00 sys=0.00, real=0.00 secs]<sup>7</sup></span></p>
</div>

1. **2015-05-26T16:23:07.321-0200: 64.42** -GC事件开始的时间. 其中 -0200 是时区,而中国所在的东8区为 +0800。 而 64.42 是相对于JVM启动的时间。 下面的其他阶段也是一样,所以就不再重复介绍。
2. **CMS Initial Mark** -垃圾回收的阶段名称为 “Initial Mark”。 标记所有的 GC Root
3. **10812086K** – 老年代的当前使用量。
4. **(11901376K)** – 老年代中可用内存总量。
5. **10887844K** – 当前堆内存的使用量。
6. **(12514816K)** – 可用堆的总大小。
7. **0.0001997 secs] [Times: user=0.00 sys=0.00, real=0.00 secs]**  -此次暂停的持续时间, 以 user, system 和 real time 3个部分进行衡量。

- user – 在此次垃圾回收过程中, 由GC线程所消耗的总的CPU时间。
- sys – GC过程中中操作系统调用和系统等待事件所消耗的时间。
- real – 应用程序暂停的时间。


**阶段二: Concurrent Mark(并发标记)**. 在此阶段, 垃圾收集器遍历老年代, 标记所有的存活对象, 从前一阶段 “Initial Mark” 找到的 root 根开始算起。 顾名思义, “并发标记”阶段, 就是与应用程序同时运行,不用暂停的阶段。 请注意, 并非所有老年代中存活的对象都在此阶段被标记, 因为在标记过程中对象的引用关系还在发生变化。

![04_07_g107.png](/images/2019/04/13/49049030-5df4-11e9-94d6-37a08b4dce14.png)

在上面的示意图中, “Current object” 旁边的一个引用被标记线程并发删除了。

<div>
<pre class="code-line">2015-05-26T16:23:07.321-0200: 64.425: [CMS-concurrent-mark-start]
2015-05-26T16:23:07.357-0200: 64.460: [<span class="node">CMS-concurrent-mark<sup>1</sup></span>: <span class="node">035/0.035 secs<sup>2</sup></span>] <span class="node">[Times: user=0.07 sys=0.00, real=0.03 secs]<sup>3</sup></span></pre>
</div>


1. **CMS-concurrent-mark** – 并发标记("Concurrent Mark") 是CMS垃圾收集中的一个阶段, 遍历老年代并标记所有的存活对象。
2. **035/0.035 secs** – 此阶段的持续时间, 分别是运行时间和相应的实际时间。
3. **[Times: user=0.07 sys=0.00, real=0.03 secs]** – 这部分对并发阶段来说没多少意义, 因为是从并发标记开始时计算的,而这段时间内不仅并发标记在运行,程序也在运行


**阶段三**: **Concurrent Preclean**(并发预清理). 此阶段同样是与应用线程并行执行的, 不需要停止应用线程。 因为前一阶段是与程序并发进行的,可能有一些引用已经改变。如果在并发标记过程中发生了引用关系变化,JVM会(通过“Card”)将发生了改变的区域标记为“脏”区(这就是所谓的卡片标记,Card Marking)。
![04_08_g108.png](/images/2019/04/13/cc418480-5df4-11e9-94d6-37a08b4dce14.png)
在预清理阶段,这些脏对象会被统计出来,从他们可达的对象也被标记下来。此阶段完成后, 用以标记的 card 也就被清空了。
![04_09_g109.png](/images/2019/04/13/e3f44270-5df4-11e9-94d6-37a08b4dce14.png)


<pre class="code-line">2015-05-26T16:23:07.357-0200: 64.460: [CMS-concurrent-preclean-start]
2015-05-26T16:23:07.373-0200: 64.476: [<span class="node">CMS-concurrent-preclean<sup>1</sup></span>: <span class="node">0.016/0.016 secs<sup>2</sup></span>] <span class="node">[Times: user=0.02 sys=0.00, real=0.02 secs]<sup>3</sup></span></pre>


1. **CMS-concurrent-preclean** – 并发预清理阶段, 统计此前的标记阶段中发生了改变的对象。
2. **0.016/0.016 secs** – 此阶段的持续时间, 分别是运行时间和对应的实际时间。
3. **[Times: user=0.02 sys=0.00, real=0.02 secs]** – 部分对并发阶段来说没多少意义, 因为是从并发标记开始时计算的,而这段时间内不仅GC的并发标记在运行,程序也在运行。



**阶段四**: **Concurrent Abortable Preclean**(并发可取消的预清理). 此阶段也不停止应用线程. 本阶段尝试在 STW 的 Final Remark 之前尽可能地多做一些工作。本阶段的具体时间取决于多种因素, 因为它循环做同样的事情,直到满足某个退出条件( 如迭代次数, 有用工作量, 消耗的系统时间,等等)。


<pre class="code-line">2015-05-26T16:23:07.373-0200: 64.476: [CMS-concurrent-abortable-preclean-start]
2015-05-26T16:23:08.446-0200: 65.550: [<span class="node">CMS-concurrent-abortable-preclean<sup>1</sup></span>: <span class="node">0.167/1.074 secs<sup>2</sup></span>] <span class="node">[Times: user=0.20 sys=0.00, real=1.07 secs]<sup>3</sup></span></pre>

1. **CMS-concurrent-abortable-preclean** – 此阶段的名称: “Concurrent Abortable Preclean”。
2. **0.167/1.074 secs** – 此阶段的持续时间, 运行时间和对应的实际时间。有趣的是, 用户时间明显比时钟时间要小很多。通常情况下我们看到的都是时钟时间小于用户时间, 这意味着因为有一些并行工作, 所以运行时间才会小于使用的CPU时间。这里只进行了少量的工作 — 0.167秒的CPU时间,GC线程经历了很多系统等待。从本质上讲,GC线程试图在必须执行 STW暂停之前等待尽可能长的时间。默认条件下,此阶段可以持续最多5秒钟。
3. **[Times: user=0.20 sys=0.00, real=1.07 secs]** – 这部分对并发阶段来说没多少意义, 因为是从并发标记开始时计算的,而这段时间内不仅GC的并发标记线程在运行,程序也在运行


**阶段五**: **Final Remark(最终标记)**
这是此次GC事件中第二次(也是最后一次)STW阶段。本阶段的目标是完成老年代中所有存活对象的标记. 因为之前的 preclean 阶段是并发的, 有可能无法跟上应用程序的变化速度。所以需要 STW暂停来处理复杂情况。


<p class="code-line"><span class="node">2015-05-26T16:23:08.447-0200: 65.550<sup>1</sup></span>: [GC (<span class="node">CMS Final Remark<sup>2</sup></span>) [<span class="node">YG occupancy: 387920 K (613440 K)<sup>3</sup></span>]65.550: <span class="node">[Rescan (parallel) , 0.0085125 secs]<sup>4</sup></span>65.559: [<span class="node">weak refs processing, 0.0000243 secs]65.559<sup>5</sup></span>: [<span class="node">class unloading, 0.0013120 secs]65.560<sup>6</sup></span>: [<span class="node">scrub string table, 0.0001759 secs<sup>7</sup></span>][1 CMS-remark: <span class="node">10812086K(11901376K)<sup>8</sup></span>] <span class="node">11200006K(12514816K) <sup>9</sup></span>, <span class="node">0.0110730 secs<sup>10</sup></span>] [<span class="node">[Times: user=0.06 sys=0.00, real=0.01 secs]<sup>11</sup></span></p>


1. **2015-05-26T16:23:08.447-0200: 65.550** – GC事件开始的时间. 包括时钟时间,以及相对于JVM启动的时间. 其中-0200表示西二时区,而中国所在的东8区为 +0800。
2. **CMS Final Remark** – 此阶段的名称为 “Final Remark”, 标记老年代中所有存活的对象，包括在此前的并发标记过程中创建/修改的引用。
3. **YG occupancy: 387920 K (613440 K)** -当前年轻代的使用量和总容量。
4. **[Rescan (parallel) , 0.0085125 secs]** – 在程序暂停时重新进行扫描(Rescan),以完成存活对象的标记。此时 rescan 是并行执行的,消耗的时间为 0.0085125秒。
5. **weak refs processing, 0.0000243 secs]65.559** – 处理弱引用的第一个子阶段(sub-phases)。 显示的是持续时间和开始时间戳。
6. **class unloading, 0.0013120 secs]65.560** – 第二个子阶段, 卸载不使用的类。 显示的是持续时间和开始的时间戳。
7. **scrub string table, 0.0001759 secs** – 最后一个子阶段, 清理持有class级别 metadata 的符号表(symbol tables),以及内部化字符串对应的 string tables。当然也显示了暂停的时钟时间。
8. **10812086K(11901376K)** – 此阶段完成后老年代的使用量和总容量
9. **11200006K(12514816K)** – 此阶段完成后整个堆内存的使用量和总容量
10. **0.0110730 secs** – 此阶段的持续时间。
11. **[Times: user=0.06 sys=0.00, real=0.01 secs]** – GC事件的持续时间, 通过不同的类别来衡量: user, system and real time。

在5个标记阶段完成之后, 老年代中所有的存活对象都被标记了, 现在GC将清除所有不使用的对象来回收老年代空间:

**阶段六**: **Concurrent Sweep**(并发清除). 此阶段与应用程序并发执行,不需要STW停顿。目的是删除未使用的对象,并收回他们占用的空间。
![04_10_g110.png](/images/2019/04/13/572c9120-5df5-11e9-94d6-37a08b4dce14.png)


<p class="code-line">2015-05-26T16:23:08.458-0200: 65.561: [CMS-concurrent-sweep-start]
2015-05-26T16:23:08.485-0200: 65.588: [<span class="node">CMS-concurrent-sweep<sup>1</sup></span>: <span class="node">0.027/0.027 secs<sup>2</sup></span>] [<span class="node">[Times: user=0.03 sys=0.00, real=0.03 secs] <sup>3</sup></span></p>

1. **CMS-concurrent-sweep** – 此阶段的名称, “Concurrent Sweep”, 清除未被标记、不再使用的对象以释放内存空间。
2. **0.027/0.027 secs** – 此阶段的持续时间, 分别是运行时间和实际时间
3. **[Times: user=0.03 sys=0.00, real=0.03 secs] ** – “Times”部分对并发阶段来说没有多少意义, 因为是从并发标记开始时计算的,而这段时间内不仅是并发标记在运行,程序也在运行。


**阶段七**: **Concurrent Reset**(并发重置). 此阶段与应用程序并发执行,重置CMS算法相关的内部数据, 为下一次GC循环做准备。
<p class="code-line">2015-05-26T16:23:08.485-0200: 65.589: [CMS-concurrent-reset-start]
2015-05-26T16:23:08.497-0200: 65.601: [<span class="node">CMS-concurrent-reset<sup>1</sup></span>: <span class="node">0.012/0.012 secs<sup>2</sup></span>] [<span class="node">[Times: user=0.01 sys=0.00, real=0.01 secs]<sup>3</sup></span></p>

1. **CMS-concurrent-reset** – 此阶段的名称, “Concurrent Reset”, 重置CMS算法的内部数据结构, 为下一次GC循环做准备。
2. **0.012/0.012 secs** – 此阶段的持续时间, 分别是运行时间和对应的实际时间
3. **[Times: user=0.01 sys=0.00, real=0.01 secs]** – “Times”部分对并发阶段来说没多少意义, 因为是从并发标记开始时计算的,而这段时间内不仅GC线程在运行,程序也在运行。

# G1
G1最主要的设计目标是: 将STW停顿的时间和分布变成可预期以及可配置的。事实上, G1是一款软实时垃圾收集器, 也就是说可以为其设置某项特定的性能指标. 可以指定: 在任意 xx 毫秒的时间范围内, STW停顿不得超过 x 毫秒。 如: 任意1秒暂停时间不得超过5毫秒. Garbage-First GC 会尽力达成这个目标(有很大的概率会满足, 但并不完全确定,具体是多少将是硬实时的[hard real-time])。

G1 GC 是一个压缩收集器，它基于回收最大量的垃圾原理进行设计。G1 GC 利用递增、并行、独占暂停这些属性，通过拷贝方式完成压缩目标。此外，它也借助并行、多阶段并行标记这些方式来帮助减少标记、重标记、清除暂停的停顿时间，让停顿时间最小化是它的设计目标之一。

为了达成这项指标, G1 有一些独特的实现。首先, 堆不再分成连续的年轻代和老年代空间。而是划分为多个(通常是2048个)可以存放对象的 小堆区(smaller heap regions)。每个小堆区都可能是 Eden区, Survivor区或者Old区. 每个 Region 都有一个关联的 Remembered Set（简称 RS），RS 的数据结构是 Hash 表，里面的数据是 Card Table （堆中每 512byte 映射在 card table 1byte）。在逻辑上, 所有的Eden区和Survivor区合起来就是年轻代, 所有的Old区拼在一起那就是老年代:
![04_11_g1011.png](/images/2019/04/14/4c74ddb0-5e76-11e9-9e00-0598c74bdc4f.png)

简单的说 RS 里面存在的是 Region 中存活对象的指针。当 Region 中数据发生变化时，首先反映到 Card Table 中的一个或多个 Card 上，RS 通过扫描内部的 Card Table 得知 Region 中内存使用情况和存活对象。在使用 Region 过程中，如果 Region 被填满了，分配内存的线程会重新选择一个新的 Region，空闲 Region 被组织到一个基于链表的数据结构（LinkedList）里面，这样可以快速找到新的 Region。
这样的划分使得 GC不必每次都去收集整个堆空间, 而是以增量的方式来处理: 每次只处理一部分小堆区,称为此次的回收集(collection set). 每次暂停都会收集所有年轻代的小堆区, 但可能只包含一部分老年代小堆区:
![04_12_g102.png](/images/2019/04/14/52f0dea0-5e76-11e9-9e00-0598c74bdc4f.png)

G1的另一项创新, 是在并发阶段估算每个小堆区存活对象的总数。用来构建回收集(collection set)的原则是: 垃圾最多的小堆区会被优先收集。这也是G1名称的由来: garbage-first。


要启用G1收集器, 使用的命令行参数为:

` java -XX:+UseG1GC com.mypackages.MyExecutableClass `

### Evacuation Pause: Fully Young(转移暂停:纯年轻代模式)
在应用程序刚启动时, G1还未执行过(not-yet-executed)并发阶段, 也就没有获得任何额外的信息, 处于初始的 fully-young 模式. 在年轻代空间用满之后, 应用线程被暂停, 年轻代堆区中的存活对象被复制到存活区, 如果还没有存活区,则选择任意一部分空闲的小堆区用作存活区。

复制的过程称为转移(Evacuation), 这和前面讲过的年轻代收集器基本上是一样的工作原理。转移暂停的日志信息很长,为简单起见, 我们去除了一些不重要的信息. 在并发阶段之后我们会进行详细的讲解。此外, 由于日志记录很多, 所以并行阶段和“其他”阶段的日志将拆分为多个部分来进行讲解:

<p class="code-line nowrap"><span class="node">0.134: [GC pause (G1 Evacuation Pause) (young), 0.0144119 secs]<sup>1</sup></span><br>&nbsp;&nbsp;&nbsp;&nbsp;<span class="node">[Parallel Time: 13.9 ms, GC Workers: 8]<sup>2</sup></span><br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="node">…<sup>3</sup></span><br>&nbsp;&nbsp;&nbsp;&nbsp;<span class="node">[Code Root Fixup: 0.0 ms]<sup>4</sup></span><br>&nbsp;&nbsp;&nbsp;&nbsp;<span class="node">[Code Root Purge: 0.0 ms]<sup>5</sup></span><br>&nbsp;&nbsp;&nbsp;&nbsp;<code>[Clear CT: 0.1 ms]</code><br>&nbsp;&nbsp;&nbsp;&nbsp;<span class="node">[Other: 0.4 ms]<sup>6</sup></span><br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="node">…<sup>7</sup></span><br>&nbsp;&nbsp;&nbsp;&nbsp;<span class="node">[Eden: 24.0M(24.0M)-&gt;0.0B(13.0M) <sup>8</sup></span><span class="node">Survivors: 0.0B-&gt;3072.0K <sup>9</sup></span><span class="node">Heap: 24.0M(256.0M)-&gt;21.9M(256.0M)]<sup>10</sup></span><br>&nbsp;&nbsp;&nbsp;&nbsp;<span class="node"> [Times: user=0.04 sys=0.04, real=0.02 secs] <sup>11</sup></span></p>


1. **0.134: [GC pause (G1 Evacuation Pause) (young), 0.0144119 secs]** – G1转移暂停,只清理年轻代空间。暂停在JVM启动之后 134 ms 开始, 持续的系统时间为 0.0144秒 。
2. **[Parallel Time: 13.9 ms, GC Workers: 8]** – 表明后面的活动由8个 Worker 线程并行执行, 消耗时间为13.9毫秒(real time)。
3. **…** –为阅读方便, 省略了部分内容,请参考后文。
4. **[Code Root Fixup: 0.0 ms]** –释放用于管理并行活动的内部数据。一般都接近于零。这是串行执行的过程。
5. **[Code Root Purge: 0.0 ms]** –清理其他部分数据, 也是非常快的, 但如非必要则几乎等于零。这是串行执行的过程。
6. **[Other: 0.4 ms]** –其他活动消耗的时间, 其中有很多是并行执行的。
7. **…** – 请参考后文。
8. **[Eden: 24.0M(24.0M)-&gt;0.0B(13.0M) ** – 暂停之前和暂停之后, Eden 区的使用量/总容量。
9. **Survivors: 0.0B-&gt;3072.0K** –暂停之前和暂停之后, 存活区的使用量。
10. **Heap: 24.0M(256.0M)-&gt;21.9M(256.0M)]** –暂停之前和暂停之后, 整个堆内存的使用量与总容量。
11. **[Times: user=0.04 sys=0.04, real=0.02 secs]** –GC事件的持续时间, 通过三个部分来衡量:
- user – 在此次垃圾回收过程中, 由GC线程所消耗的总的CPU时间。
- sys – GC过程中, 系统调用和系统等待事件所消耗的时间。
- real – 应用程序暂停的时间。在parallelizable并行GC中, 这个数字约等于: (user time + system time)/GC线程数。 这里使用的是8个线程。 请注意,总是有一定比例的处理过程是不能并行化的。

最繁重的GC任务由多个专用的 worker 线程来执行。下面的日志描述了他们的行为:

<p class="code-line nowrap"><span class="node">[Parallel Time: 13.9 ms, GC Workers: 8]<sup>1</sup></span><br>&nbsp;&nbsp;&nbsp;&nbsp;<span class="node"> [GC Worker Start (ms)<sup>2</sup></span><code>: Min: 134.0, Avg: 134.1, Max: 134.1, Diff: 0.1]</code><br>&nbsp;&nbsp;&nbsp;&nbsp;<span class="node">[Ext Root Scanning (ms)<sup>3</sup></span><code>: Min: 0.1, Avg: 0.2, Max: 0.3, Diff: 0.2, Sum: 1.2]</code><br>&nbsp;&nbsp;&nbsp;&nbsp;<code>[Update RS (ms): Min: 0.0, Avg: 0.0, Max: 0.0, Diff: 0.0, Sum: 0.0]</code><br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<code>[Processed Buffers: Min: 0, Avg: 0.0, Max: 0, Diff: 0, Sum: 0]</code><br>&nbsp;&nbsp;&nbsp;&nbsp;<code>[Scan RS (ms): Min: 0.0, Avg: 0.0, Max: 0.0, Diff: 0.0, Sum: 0.0]</code><br>&nbsp;&nbsp;&nbsp;&nbsp;<span class="node">[Code Root Scanning (ms)<sup>4</sup></span><code>: Min: 0.0, Avg: 0.0, Max: 0.2, Diff: 0.2, Sum: 0.2]</code><br>&nbsp;&nbsp;&nbsp;&nbsp;<span class="node">[Object Copy (ms)<sup>5</sup></span><code>: Min: 10.8, Avg: 12.1, Max: 12.6, Diff: 1.9, Sum: 96.5]</code><br>&nbsp;&nbsp;&nbsp;&nbsp;<span class="node">[Termination (ms)<sup>6</sup></span><code>: Min: 0.8, Avg: 1.5, Max: 2.8, Diff: 1.9, Sum: 12.2]</code><br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="node">[Termination Attempts<sup>7</sup></span><code>: Min: 173, Avg: 293.2, Max: 362, Diff: 189, Sum: 2346]</code><br>&nbsp;&nbsp;&nbsp;&nbsp;<span class="node">[GC Worker Other (ms)<sup>8</sup></span><code>: Min: 0.0, Avg: 0.0, Max: 0.0, Diff: 0.0, Sum: 0.1]</code><br>&nbsp;&nbsp;&nbsp;&nbsp;<span class="node">GC Worker Total (ms)<sup>9</sup></span><code>: Min: 13.7, Avg: 13.8, Max: 13.8, Diff: 0.1, Sum: 110.2]</code><br>&nbsp;&nbsp;&nbsp;&nbsp;<span class="node">[GC Worker End (ms)<sup>10</sup></span>: Min: 147.8, Avg: 147.8, Max: 147.8, Diff: 0.0]
</p>

1. **[Parallel Time: 13.9 ms, GC Workers: 8]** – 表明下列活动由8个线程并行执行,消耗的时间为13.9毫秒(real time)。
2. **[GC Worker Start (ms)** – GC的worker线程开始启动时,相对于 pause 开始的时间戳。如果 Min 和 Max 差别很大,则表明本机其他进程所使用的线程数量过多, 挤占了GC的CPU时间。
3. **[Ext Root Scanning (ms)** – 用了多长时间来扫描堆外(non-heap)的root, 如 classloaders, JNI引用, JVM的系统root等。后面显示了运行时间, “Sum” 指的是CPU时间。
4. **[Code Root Scanning (ms)** – 用了多长时间来扫描实际代码中的 root: 例如局部变量等等(local vars)。
5. **[Object Copy (ms)** – 用了多长时间来拷贝收集区内的存活对象。
6. **[Termination (ms)** – GC的worker线程用了多长时间来确保自身可以安全地停止, 这段时间什么也不用做, stop 之后该线程就终止运行了。
7. **[Termination Attempts** – GC的worker 线程尝试多少次 try 和 teminate。如果worker发现还有一些任务没处理完,则这一次尝试就是失败的, 暂时还不能终止。
8. **[GC Worker Other (ms)** – 一些琐碎的小活动,在GC日志中不值得单独列出来。
9. **GC Worker Total (ms)** – GC的worker 线程的工作时间总计。
10. **[GC Worker End (ms)** – GC的worker 线程完成作业的时间戳。通常来说这部分数字应该大致相等, 否则就说明有太多的线程被挂起, 很可能是因为坏邻居效应(noisy neighbor) 所导致的。

此外,在转移暂停期间,还有一些琐碎执行的小活动。这里我们只介绍其中的一部分, 其余的会在后面进行讨论。
<p class="code-line nowrap"><span class="node">[Other: 0.4 ms]<sup>1</sup></span><br>&nbsp;&nbsp;&nbsp;&nbsp;<code>[Choose CSet: 0.0 ms]</code><br>&nbsp;&nbsp;&nbsp;&nbsp;<span class="node">[Ref Proc: 0.2 ms]<sup>2</sup></span><br>&nbsp;&nbsp;&nbsp;&nbsp;<span class="node">[Ref Enq: 0.0 ms]<sup>3</sup></span><br>&nbsp;&nbsp;&nbsp;&nbsp;<code>[Redirty Cards: 0.1 ms]</code><br>&nbsp;&nbsp;&nbsp;&nbsp;<code>[Humongous Register: 0.0 ms]</code><br>&nbsp;&nbsp;&nbsp;&nbsp;<code>[Humongous Reclaim: 0.0 ms]</code><br>&nbsp;&nbsp;&nbsp;&nbsp;<span class="node">[Free CSet: 0.0 ms]<sup>4</sup></span></p>
1. **[Other: 0.4 ms]** – 其他活动消耗的时间, 其中有很多也是并行执行的。
2. **[Ref Proc: 0.2 ms]** – 处理非强引用(non-strong)的时间: 进行清理或者决定是否需要清理。
3. **[Ref Enq: 0.0 ms]** – 用来将剩下的 non-strong 引用排列到合适的 ReferenceQueue中。
4. **[Free CSet: 0.0 ms]** – 将回收集中被释放的小堆归还所消耗的时间, 以便他们能用来分配新的对象。

### Concurrent Marking(并发标记)

G1收集器的很多概念建立在CMS的基础上,所以下面的内容需要你对CMS有一定的理解. 虽然也有很多地方不同, 但并发标记的目标基本上是一样的. G1的并发标记通过 **Snapshot-At-The-Beginning(开始时快照)** 的方式, 在标记阶段开始时记下所有的存活对象。即使在标记的同时又有一些变成了垃圾. 通过对象是存活信息, 可以构建出每个小堆区的存活状态, 以便回收集能高效地进行选择。

这些信息在接下来的阶段会用来执行老年代区域的垃圾收集。在两种情况下是完全地并发执行的： 一、如果在标记阶段确定某个小堆区只包含垃圾; 二、在STW转移暂停期间, 同时包含垃圾和存活对象的老年代小堆区。

当堆内存的总体使用比例达到一定数值时,就会触发并发标记。默认值为 45%, 但也可以通过JVM参数 **InitiatingHeapOccupancyPercent** 来设置。和CMS一样, G1的并发标记也是由多个阶段组成, 其中一些是完全并发的, 还有一些阶段需要暂停应用线程。

**阶段 1: Initial Mark(初始标记)。** 此阶段标记所有从GC root 直接可达的对象。在CMS中需要一次STW暂停, 但G1里面通常是在转移暂停的同时处理这些事情, 所以它的开销是很小的. 可以在 Evacuation Pause 日志中的第一行看到(initial-mark)暂停:
```
1.631: [GC pause (G1 Evacuation Pause) (young) (initial-mark), 0.0062656 secs]
```
**阶段 2: Root Region Scan(Root区扫描)**. 此阶段标记所有从 "根区域" 可达的存活对象。 根区域包括: 非空的区域, 以及在标记过程中不得不收集的区域。因为在并发标记的过程中迁移对象会造成很多麻烦, 所以此阶段必须在下一次转移暂停之前完成。如果必须启动转移暂停, 则会先要求根区域扫描中止, 等它完成才能继续扫描. 在当前版本的实现中, 根区域是存活的小堆区: y包括下一次转移暂停中肯定会被清理的那部分年轻代小堆区。
```
1.362: [GC concurrent-root-region-scan-start]
1.364: [GC concurrent-root-region-scan-end, 0.0028513 secs]
```
**阶段 3: Concurrent Mark(并发标记).** 此阶段非常类似于CMS: 它只是遍历对象图, 并在一个特殊的位图中标记能访问到的对象. 为了确保标记开始时的快照准确性, 所有应用线程并发对对象图执行的引用更新,G1 要求放弃前面阶段为了标记目的而引用的过时引用。

这是通过使用 **Pre-Write** 屏障来实现的,(不要和之后介绍的 **Post-Write** 混淆, 也不要和多线程开发中的内存屏障(memory barriers)相混淆)。Pre-Write屏障的作用是: G1在进行并发标记时, 如果程序将对象的某个属性做了变更, 就会在 log buffers 中存储之前的引用。 由并发标记线程负责处理。
```
1.364: [GC concurrent-mark-start]
1.645: [GC co ncurrent-mark-end, 0.2803470 secs]
```
**阶段 4: Remark(再次标记).** 和CMS类似,这也是一次STW停顿,以完成标记过程。对于G1,它短暂地停止应用线程, 停止并发更新日志的写入, 处理其中的少量信息, 并标记所有在并发标记开始时未被标记的存活对象。这一阶段也执行某些额外的清理, 如引用处理(参见 Evacuation Pause log) 或者类卸载(class unloading)。
```
1.645: [GC remark 1.645: [Finalize Marking, 0.0009461 secs]
1.646: [GC ref-proc, 0.0000417 secs] 1.646: 
	[Unloading, 0.0011301 secs], 0.0074056 secs]
[Times: user=0.01 sys=0.00, real=0.01 secs]
```
**阶段 5: Cleanup(清理).** 最后这个小阶段为即将到来的转移阶段做准备, 统计小堆区中所有存活的对象, 并将小堆区进行排序, 以提升GC的效率. 此阶段也为下一次标记执行所有必需的整理工作(house-keeping activities): 维护并发标记的内部状态。

最后要提醒的是, 所有不包含存活对象的小堆区在此阶段都被回收了。有一部分是并发的: 例如空堆区的回收,还有大部分的存活率计算, 此阶段也需要一个短暂的STW暂停, 以不受应用线程的影响来完成作业. 这种STW停顿的日志如下:

1.652: [GC cleanup 1213M->1213M(1885M), 0.0030492 secs]
[Times: user=0.01 sys=0.00, real=0.00 secs]
如果发现某些小堆区中只包含垃圾, 则日志格式可能会有点不同, 如: 
```
 1.872: [GC cleanup 1357M->173M(1996M), 0.0015664 secs] [Times: user=0.01 sys=0.00, real=0.01 secs] 
1.874: [GC concurrent-cleanup-start] 
1.876: [GC concurrent-cleanup-end, 0.0014846 secs]
```

### Evacuation Pause: Mixed (转移暂停: 混合模式)
能并发清理老年代中整个整个的小堆区是一种最优情形, 但有时候并不是这样。并发标记完成之后, G1将执行一次混合收集(mixed collection), 不只清理年轻代, 还将一部分老年代区域也加入到 collection set 中。

混合模式的转移暂停(Evacuation pause)不一定紧跟着并发标记阶段。有很多规则和历史数据会影响混合模式的启动时机。比如, 假若在老年代中可以并发地腾出很多的小堆区,就没有必要启动混合模式。

因此, 在并发标记与混合转移暂停之间, 很可能会存在多次 fully-young 转移暂停。

添加到回收集的老年代小堆区的具体数字及其顺序, 也是基于许多规则来判定的。 其中包括指定的软实时性能指标, 存活性,以及在并发标记期间收集的GC效率等数据, 外加一些可配置的JVM选项. 混合收集的过程, 很大程度上和前面的 fully-young gc 是一样的, 但这里我们还要介绍一个概念: remembered sets(历史记忆集)。

Remembered sets (历史记忆集)是用来支持不同的小堆区进行独立回收的。例如,在收集A、B、C区时, 我们必须要知道是否有从D区或者E区指向其中的引用, 以确定他们的存活性. 但是遍历整个堆需要相当长的时间, 这就违背了增量收集的初衷, 因此必须采取某种优化手段. 其他GC算法有独立的 Card Table 来支持年轻代的垃圾收集一样, 而G1中使用的是 Remembered Sets。

如下图所示, 每个小堆区都有一个 remembered set, 列出了从外部指向本区的所有引用。这些引用将被视为附加的 GC root. 注意,在并发标记过程中,老年代中被确定为垃圾的对象会被忽略, 即使有外部引用指向他们: 因为在这种情况下引用者也是垃圾。
![04_13_g103.png](/images/2019/05/12/63fe6d20-748d-11e9-bd78-078ef609bd23.png)
接下来的行为,和其他垃圾收集器一样: 多个GC线程并行地找出哪些是存活对象,确定哪些是垃圾:
![04_14_g104.png](/images/2019/05/12/7671efe0-748d-11e9-bd78-078ef609bd23.png)
最后, 存活对象被转移到存活区(survivor regions), 在必要时会创建新的小堆区。现在,空的小堆区被释放, 可用于存放新的对象了。
![04_15_g105v2.png](/images/2019/05/12/83b72760-748d-11e9-bd78-078ef609bd23.png)

为了维护 remembered set, 在程序运行的过程中, 只要写入某个字段,就会产生一个 Post-Write 屏障。如果生成的引用是跨区域的(cross-region),即从一个区指向另一个区, 就会在目标区的Remembered Set中,出现一个对应的条目。为了减少 Write Barrier 造成的开销, 将卡片放入Remembered Set 的过程是异步的, 而且经过了很多的优化. 总体上是这样: Write Barrier 把脏卡信息存放到本地缓冲区(local buffer), 有专门的GC线程负责收集, 并将相关信息传给被引用区的 remembered set。

混合模式下的日志, 和纯年轻代模式相比, 可以发现一些有趣的地方:

<p class="code-line nowrap"><span class="node">[Update RS (ms)<sup>1</sup></span><code>: Min: 0.7, Avg: 0.8, Max: 0.9, Diff: 0.2, Sum: 6.1]</code><br><span class="node">[Processed Buffers<sup>2</sup></span><code>: Min: 0, Avg: 2.2, Max: 5, Diff: 5, Sum: 18]</code><br><span class="node">[Scan RS (ms)<sup>3</sup></span><code>: Min: 0.0, Avg: 0.1, Max: 0.2, Diff: 0.2, Sum: 0.8]</code><br><span class="node">[Clear CT: 0.2 ms]<sup>4</sup></span><br><span class="node">[Redirty Cards: 0.1 ms]<sup>5</sup></span></p>
1. `[Update RS (ms)` – 因为 Remembered Sets 是并发处理的,必须确保在实际的垃圾收集之前, 缓冲区中的 card 得到处理。如果card数量很多, 则GC并发线程的负载可能就会很高。可能的原因是, 修改的字段过多, 或者CPU资源受限。
2. `[Processed Buffers` – 每个 worker 线程处理了多少个本地缓冲区(local buffer)。
3. `[Scan RS (ms)` – 用了多长时间扫描来自RSet的引用。
4. `[Clear CT: 0.2 ms]` – 清理 card table 中 cards 的时间。清理工作只是简单地删除“脏”状态, 此状态用来标识一个字段是否被更新的, 供Remembered Sets使用。
5. `[Redirty Cards: 0.1 ms]` – 将 card table 中适当的位置标记为 dirty 所花费的时间。"适当的位置"是由GC本身执行的堆内存改变所决定的, 例如引用排队等。


可以看到, G1 解决了 CMS 中的各种疑难问题, 包括暂停时间的可预测性, 并终结了堆内存的碎片化。当然,这种降低延迟的优化也不是没有代价的: 由于额外的写屏障(write barriers)和更积极的守护线程, G1的开销会更大。所以, 如果系统属于吞吐量优先型的, 又或者CPU持续占用100%, 而又不在乎单次GC的暂停时间, 那么CMS是更好的选择。

总之: G1适合大内存,需要低延迟的场景。
