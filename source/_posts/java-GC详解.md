---
title: java GC详解
tags:
  - java
categories:
  - java
toc: false
date: 2018-11-02 15:09:29
---

Java garbage collection is an automatic process to manage the runtime memory used by programs. By doing it automatic JVM relieves the programmer of the overhead of assigning and freeing up memory resources in a program.
java 与 C语言相比的一个优势是，可以通过自己的JVM自动分配和回收内存空间。

# 何为GC？
顾名思义,垃圾收集(Garbage Collection)的意思就是 —— 找到垃圾并进行清理。但现有的垃圾收集实现却恰恰相反: 垃圾收集器跟踪所有正在使用的对象,并把其余部分当做垃圾。
GC是后台的守护进程。它的特别之处是它是一个低优先级进程，但是可以根据内存的使用情况动态的调整他的优先级。因此，它是在内存中低到一定限度时才会自动运行，从而实现对内存的回收。这就是垃圾回收的时间不确定的原因。

为何要这样设计：因为GC也是进程，也要消耗CPU等资源，如果GC执行过于频繁会对java的程序的执行产生较大的影响（java解释器本来就不快），因此JVM的设计者们选着了不定期的gc。


 在JVM的五个内存区域中，有3个是不需要进行垃圾回收的：本地方法栈、程序计数器、虚拟机栈。因为他们的生命周期是和线程同步的，随着线程的销毁，他们占用的内存会自动释放。所以，只有方法区和堆区需要进行垃圾回收，回收的对象就是那些不存在任何引用的对象。


程序运行期间，所有对象实例存储在运行时数据区域的heap中，当一个对象不再被引用（使用），它就需要被收回。在GC过程中，这些不再被使用的对象从heap中收回，这样就会有空间被循环利用。

# 如何识别垃圾，判定对象是否可被回收？

### ​引用计数法
![01_01_JavaGCcountingreferences1.png](/images/2019/04/12/f9af77d0-5cd0-11e9-b3e6-9b6b7bdcccd7.png)

给每个对象添加一个计数器，当有地方引用该对象时计数器加1，当引用失效时计数器减1。
蓝色的圆圈表示可以引用到的对象, 里面的数字就是引用计数。然后, 灰色的圆圈是各个作用域都不再引用的对象。灰色的对象被认为是垃圾, 随时会被垃圾收集器清理。

缺点：循环引用的问题(当两个对象相互引用，但是二者都已经没有作用时)
![01_02_JavaGCcyclicaldependencies.png](/images/2019/04/12/82f58700-5cd1-11e9-b3e6-9b6b7bdcccd7.png)
图中红色的对象实际上属于垃圾


### 可达性分析法
通过“GC ROOTs”的对象作为搜索起始点，通过引用向下搜索，所走过的路径称为引用链。通过对象是否有到达引用链的路径来判断对象是否可被回收

![01_03_JavaGCmarkandsweep.png](/images/2019/04/12/6428e500-5cd2-11e9-b3e6-9b6b7bdcccd7.png)


#### 可作为GC ROOTs的对象
1. 虚拟机栈中引用的对象
2. 方法区中类静态属性引用的对象
3. 方法区中常量引用的对象
4. 本地方法栈中JNI引用的对象



# 引用类型
JVM中将对象的引用分为了四种类型，不同的对象引用类型会造成GC采用不同的方法进行回收：
（1）强引用：默认情况下，对象采用的均为强引用（GC不会回收）
（2）软引用：软引用是Java中提供的一种比较适合于缓存场景的应用（只有在内存不够用的情况下才会被GC）
（3）弱引用：在GC时一定会被GC回收
（4）虚引用：在GC时一定会被GC回收


# GC算法

## 标记对象
参考上面的 **可达性分析**

存活对象在上图中用蓝色表示。而其他对象(上图中灰色的数据结构)就是从GC根元素不可达的, 也就是说程序不能再使用这些不可达的对象(unreachable object)。这样的对象被认为是垃圾, GC会在接下来的阶段中清除他们。

在标记阶段有几个需要注意的点:

在标记阶段,需要暂停所有应用线程, 以遍历所有对象的引用关系。因为不暂停就没法跟踪一直在变化的引用关系图。这种情景叫做 Stop The World pause (全线停顿),而可以安全地暂停线程的点叫做安全点(safe point), 然后, JVM就可以专心执行清理工作。安全点可能有多种因素触发, 当前, GC是触发安全点最常见的原因。

此阶段暂停的时间, 与堆内存大小,对象的总数没有直接关系, 而是由存活对象(alive objects)的数量来决定。所以增加堆内存的大小并不会直接影响标记阶段占用的时间。

标记 阶段完成后, GC进行下一步操作, 删除不可达对象。

## 清除对象
1. Sweep(清除)
Mark and Sweep(标记-清除) 算法的概念非常简单: 直接忽略所有的垃圾。也就是说在标记阶段完成后, 所有不可达对象占用的内存空间, 都被认为是空闲的, 因此可以用来分配新对象。
![03_02_GCsweep.png](/images/2019/04/12/b7c7e350-5d09-11e9-b3e6-9b6b7bdcccd7.png)
**不足**：能会产生大量的内存碎片，进而引发两个问题: （1）写入操作越来越耗时, 因为寻找一块足够大的空闲内存会变得非常麻烦。（2）在创建新对象时, JVM在连续的块中分配内存。如果碎片问题很严重, 直至没有空闲片段能存放下新创建的对象,就会发生内存分配错误(allocation error)。

2. Compact(整理)
**标记-清除-整理算法**(Mark-Sweep-Compact), 将所有被标记的对象(存活对象), 迁移到内存空间的起始处, 消除了标记-清除算法的缺点。 
![03_03_GCmarksweepcompact.png](/images/2019/04/12/173eab70-5d0a-11e9-b3e6-9b6b7bdcccd7.png)
**不足**：GC暂停时间会增加, 因为需要将所有对象复制到另一个地方, 然后修改指向这些对象的引用。

3. Copy(复制)
**标记-复制算法**(Mark and Copy) 把内存空间划为两个相等的区域，每次只使用其中一个区域。gc时遍历当前使用区域，把正在使用中的对象复制到另外一个区域中.同时复制过去以后还能进行相应的内存整理，不会出现“碎片”问题
![03_04_GCmarkandcopyinJava.png](/images/2019/04/12/7219cb60-5d0a-11e9-b3e6-9b6b7bdcccd7.png)
**不足**：1.内存利用率问题2.在对象存活率较高时，其效率会变低。





# 分代GC

![02_03_javaheapedensurvivorold.png](/images/2019/04/12/500ab0f0-5cfd-11e9-b3e6-9b6b7bdcccd7.png)

### Eden 伊甸园
Eden区用来分配新创建的对象。通常会有多个线程同时创建多个对象, 所以 Eden 区被划分为多个 **线程本地分配缓冲区**(Thread Local Allocation Buffer, 简称TLAB)。通过这种缓冲区划分,大部分对象直接由JVM 在对应线程的TLAB中分配, 避免与其他线程的同步操作。

如果 TLAB 中没有足够的内存空间, 就会在共享Eden区(shared Eden space)之中分配。如果共享Eden区也没有足够的空间, 就会触发一次 年轻代GC 来释放内存空间。如果GC之后 Eden 区依然没有足够的空闲内存区域, 则对象就会被分配到老年代空间(Old Generation)。

当 Eden 区进行垃圾收集时, GC将所有从 root 可达的对象过一遍, 并标记为存活对象。

我们曾指出,对象间可能会有跨代的引用, 所以需要一种方法来标记从其他分代中指向Eden的所有引用。这样做又会遭遇各个分代之间一遍又一遍的引用。JVM在实现时采用了一些绝招: 卡片标记(card-marking)。从本质上讲,JVM只需要记住Eden区中 “脏”对象的粗略位置, 可能有老年代的对象引用指向这部分区间。
![02_04_TLABinEdenmemory.png](/images/2019/04/12/6a57a1c0-5cfd-11e9-b3e6-9b6b7bdcccd7.png)

标记阶段完成后, Eden中所有存活的对象都会被复制到存活区(Survivor spaces)里面。整个Eden区就可以被认为是空的, 然后就能用来分配新对象。这种方法称为 “标记-复制”(Mark and Copy): 存活的对象被标记, 然后复制到一个存活区(注意,是复制,而不是移动)。

### Survivor Spaces 存活区
Eden 区的旁边是两个存活区, 称为 from 空间和 to 空间。需要着重强调的的是, 任意时刻总有一个存活区是空的(empty)。

空的那个存活区用于在下一次年轻代GC时存放收集的对象。年轻代中所有的存活对象(包括Edenq区和非空的那个 "from" 存活区)都会被复制到 ”to“ 存活区。GC过程完成后, ”to“ 区有对象,而 'from' 区里没有对象。两者的角色进行正好切换 。

![02_05_howjavagcworks.png](/images/2019/04/12/f8e65010-5cff-11e9-b3e6-9b6b7bdcccd7.png)

存活的对象会在两个存活区之间复制多次, 直到某些对象的存活 时间达到一定的阀值。分代理论假设, 存活超过一定时间的对象很可能会继续存活更长时间。

这类“ 年老” 的对象因此被提升(promoted )到老年代。提升的时候， 存活区的对象不再是复制到另一个存活区,而是迁移到老年代, 并在老年代一直驻留, 直到变为不可达对象。

为了确定一个对象是否“足够老”, 可以被提升(Promotion)到老年代，GC模块跟踪记录每个存活区对象存活的次数。每次分代GC完成后,存活对象的年龄就会增长。当年龄超过提升阈值(tenuring threshold), 就会被提升到老年代区域。

具体的提升阈值由JVM动态调整,但也可以用参数 -XX:+MaxTenuringThreshold 来指定上限。如果设置 -XX:+MaxTenuringThreshold=0 , 则GC时存活对象不在存活区之间复制，直接提升到老年代。现代 JVM 中这个阈值默认设置为15个 GC周期。这也是HotSpot中的最大值。

如果存活区空间不够存放年轻代中的存活对象，提升(Promotion)也可能更早地进行。

老年代(Old Generation)
老年代的GC实现要复杂得多。老年代内存空间通常会更大，里面的对象是垃圾的概率也更小。

老年代GC发生的频率比年轻代小很多。同时, 因为预期老年代中的对象大部分是存活的, 所以不再使用标记和复制(Mark and Copy)算法。而是采用移动对象的方式来实现最小化内存碎片。老年代空间的清理算法通常是建立在不同的基础上的。原则上,会执行以下这些步骤:

通过标志位(marked bit),标记所有通过 GC roots 可达的对象.

删除所有不可达对象

整理老年代空间中的内容，方法是将所有的存活对象复制,从老年代空间开始的地方,依次存放。

通过上面的描述可知, 老年代GC必须明确地进行整理,以避免内存碎片过多。

永久代(PermGen)
在Java 8 之前有一个特殊的空间,称为“永久代”(Permanent Generation)。这是存储元数据(metadata)的地方,比如 class 信息等。此外,这个区域中也保存有其他的数据和信息, 包括 内部化的字符串(internalized strings)等等。实际上这给Java开发者造成了很多麻烦,因为很难去计算这块区域到底需要占用多少内存空间。预测失败导致的结果就是产生 java.lang.OutOfMemoryError: Permgen space 这种形式的错误。除非 ·OutOfMemoryError· 确实是内存泄漏导致的,否则就只能增加 permgen 的大小，例如下面的示例，就是设置 permgen 最大空间为 256 MB:

java -XX:MaxPermSize=256m com.mycompany.MyApplication
元数据区(Metaspace)
既然估算元数据所需空间那么复杂, Java 8直接删除了永久代(Permanent Generation)，改用 Metaspace。从此以后, Java 中很多杂七杂八的东西都放置到普通的堆内存里。

当然，像类定义(class definitions)之类的信息会被加载到 Metaspace 中。元数据区位于本地内存(native memory),不再影响到普通的Java对象。默认情况下, Metaspace的大小只受限于 Java进程可用的本地内存。这样程序就不再因为多加载了几个类/JAR包就导致 java.lang.OutOfMemoryError: Permgen space. 。注意, 这种不受限制的空间也不是没有代价的 —— 如果 Metaspace 失控, 则可能会导致很严重的内存交换(swapping), 或者导致本地内存分配失败。

如果需要避免这种最坏情况，那么可以通过下面这样的方式来限制 Metaspace 的大小, 如 256 MB:

java -XX:MaxMetaspaceSize=256m com.mycompany.MyApplication



# Minor GC vs Major GC vs Full GC
### Minor GC
年轻代内存的垃圾收集事件称为Minor GC。当JVM无法为新对象分配内存空间时总会触发 Minor GC,比如 Eden 区占满时。所以(新对象)分配频率越高, Minor GC 的频率就越高。

Minor GC 事件实际上忽略了老年代。从老年代指向年轻代的引用都被认为是GC Root。而从年轻代指向老年代的引用在标记阶段全部被忽略。
与一般的认识相反, Minor GC 每次都会引起全线停顿STW, 暂停所有的应用线程。对大多数程序而言,暂停时长基本上是可以忽略不计的, 因为 Eden 区的对象基本上都是垃圾, 也不怎么复制到存活区/老年代。如果情况不是这样, 大部分新创建的对象不能被垃圾回收清理掉, 则 Minor GC的停顿就会持续更长的时间。

### Major GC vs Full GC
这两个术语并没有正式的定义 —— 无论是在JVM规范还是在GC相关论文中。
依据Minor GC 清理的是年轻代空间(Young space)，相应的:

- Major GC  清理的是老年代空间
- Full GC 清理的是整个堆, 包括年轻代和老年代空间。

很多 Major GC 是由 Full GC 触发的, 所以很多情况下这两者是不可分离的。



三代的特点不同，造就了他们使用的GC算法不同，新生代适合生命周期较短，快速创建和销毁的对象，旧生代适合生命周期较长的对象，持久代在Sun Hotpot虚拟机中就是指方法区（有些JVM根本就没有持久代这一说法）。

Minor collection：
新生代使用将 Eden 还有 Survivor 内的数据利用 semi-space 做复制收集（Copying collection）， 并将原本 Survivor 内经过多次垃圾收集仍然存活的对象移动到 Tenured。

Major collection 则会进行 Minor collection，Tenured 世代则进行标记压缩收集。


# GC收集器
Java 8中各种垃圾收集器的组合

| Young | Tenured |JVM options|
|-|-|-|
| Incremental | Incremental |-Xincgc|
| **Serial** | **Serial** |-XX:+UseSerialGC|
| Parallel Scavenge | Serial |-XX:+UseParallelGC -XX:-UseParallelOldGC|
| Parallel New	 | Serial |N/A|
| Serial | Parallel Old |N/A|
| **Parallel Scavenge** | **Parallel Old** |-XX:+UseParallelGC -XX:+UseParallelOldGC|
| Parallel New | Parallel Old |N/A|
| Serial | CMS |-XX:-UseParNewGC -XX:+UseConcMarkSweepGC|
| Parallel Scavenge | CMS -N/A|
| **Parallel New** | **CMS** | -XX:+UseParNewGC -XX:+UseConcMarkSweepGC |
| **G1** | **G1** |--XX:+UseG1GC|

除了黑体字表示四种组合外，其余的要么是被废弃, 要么是不支持或者是不太适用于生产环境。


### Serial GC
​Serial GC是最古老也是最基本的收集器，但是现在依然广泛使用，JAVA SE5和JAVA SE6中客户端虚拟机采用的默认配置。

Serial GC 对年轻代使用 **mark-copy(标记-复制)** 算法, 对老年代使用 **mark-sweep-compact(标记-清除-整理)** 算法. 两者都是单线程的垃圾收集器,不能进行并行处理。都会触发全线暂停(STW)，停止所有的应用线程。

该收集器适用于单CPU、新生代空间较小且对暂停时间要求不是特别高的应用上

### Parallel GC
在年轻代使用 标记-复制(mark-copy)算法, 在老年代使用 标记-清除-整理(mark-sweep-compact)算法。年轻代和老年代的垃圾回收都会触发STW事件,暂停所有的应用线程来执行垃圾收集。两者在执行 标记和 复制/整理阶段时都使用多个线程, 因此得名“(Parallel)”。通过并行执行, 使得GC时间大幅减少。

并行垃圾收集器适用于多核服务器,主要目标是增加吞吐量。


##  CMS (Concurrent Mark and Sweep)

该收集器的目标是解决Serial  GC停顿的问题，以达到最短回收时间。其对年轻代采用并行STW方式的 **mark-copy** (标记-复制)算法, 对老年代主要使用并发 **mark-sweep** (标记-清除)算法。
CMS的设计目标是避免在老年代垃圾收集时出现长时间的卡顿。主要通过两种手段来达成此目标。
- 第一, 不对老年代进行整理, 而是使用空闲列表(free-lists)来管理内存空间的回收。
- 第二, 在 mark-and-sweep (标记-清除) 阶段的大部分工作和应用线程一起并发执行。

在这些阶段并没有明显的应用线程暂停。但值得注意的是, 它仍然和应用线程争抢CPU时间。默认情况下, CMS 使用的并发线程数等于CPU内核数的 1/4。

### Full GC
**阶段一：Initial Mark(初始标记)**。 此阶段的目标是标记老年代中所有存活的对象, 包括 GC ROOR 的直接引用, 以及由年轻代中存活对象所引用的对象。 后者也非常重要, 因为老年代是独立进行回收的。
![04_06_g106.png](/images/2019/04/13/a6666530-5dab-11e9-94d6-37a08b4dce14.png)

**阶段二: Concurrent Mark(并发标记)**. 在此阶段, 垃圾收集器遍历老年代, 标记所有的存活对象, 从前一阶段 “Initial Mark” 找到的 root 根开始算起。 顾名思义, “并发标记”阶段, 就是与应用程序同时运行,不用暂停的阶段。 请注意, 并非所有老年代中存活的对象都在此阶段被标记, 因为在标记过程中对象的引用关系还在发生变化。

![04_07_g107.png](/images/2019/04/13/49049030-5df4-11e9-94d6-37a08b4dce14.png)

在上面的示意图中, “Current object” 旁边的一个引用被标记线程并发删除了。

**阶段三**: **Concurrent Preclean**(并发预清理). 此阶段同样是与应用线程并行执行的, 不需要停止应用线程。 因为前一阶段是与程序并发进行的,可能有一些引用已经改变。如果在并发标记过程中发生了引用关系变化,JVM会(通过“Card”)将发生了改变的区域标记为“脏”区(这就是所谓的卡片标记,Card Marking)。
![04_08_g108.png](/images/2019/04/13/cc418480-5df4-11e9-94d6-37a08b4dce14.png)
在预清理阶段,这些脏对象会被统计出来,从他们可达的对象也被标记下来。此阶段完成后, 用以标记的 card 也就被清空了。
![04_09_g109.png](/images/2019/04/13/e3f44270-5df4-11e9-94d6-37a08b4dce14.png)

**阶段四**: **Concurrent Abortable Preclean**(并发可取消的预清理). 此阶段也不停止应用线程. 本阶段尝试在 STW 的 Final Remark 之前尽可能地多做一些工作。本阶段的具体时间取决于多种因素, 因为它循环做同样的事情,直到满足某个退出条件( 如迭代次数, 有用工作量, 消耗的系统时间,等等)。

**阶段五**: **Final Remark(最终标记)**
这是此次GC事件中第二次(也是最后一次)STW阶段。本阶段的目标是完成老年代中所有存活对象的标记. 因为之前的 preclean 阶段是并发的, 有可能无法跟上应用程序的变化速度。所以需要 STW暂停来处理复杂情况。

通常CMS会尝试在年轻代尽可能空的情况运行 final remark 阶段, 以免接连多次发生 STW 事件。

在5个标记阶段完成之后, 老年代中所有的存活对象都被标记了, 现在GC将清除所有不使用的对象来回收老年代空间:

**阶段六**: **Concurrent Sweep**(并发清除). 此阶段与应用程序并发执行,不需要STW停顿。目的是删除未使用的对象,并收回他们占用的空间。
![04_10_g110.png](/images/2019/04/13/572c9120-5df5-11e9-94d6-37a08b4dce14.png)

**阶段七**: **Concurrent Reset**(并发重置). 此阶段与应用程序并发执行,重置CMS算法相关的内部数据, 为下一次GC循环做准备。


CMS收集器的优点：并发收集、低停顿，但远没有达到完美；
CMS收集器的缺点：
- CMS收集器对CPU资源非常敏感，在并发阶段虽然不会导致用户停顿，但是会占用CPU资源而导致应用程序变慢，总吞吐量下降。
- CMS收集器无法处理浮动垃圾，可能出现“Concurrnet Mode Failure”，失败而导致另一次的Full GC。
- CMS收集器对老年代是基于mark-sweep算法的实现，因此也会产生碎片。


##  G1收集器
G1最主要的设计目标是: 将STW停顿的时间和分布变成可预期以及可配置的。事实上, G1是一款软实时垃圾收集器, 也就是说可以为其设置某项特定的性能指标. 可以指定: 在任意 xx 毫秒的时间范围内, STW停顿不得超过 x 毫秒。 如: 任意1秒暂停时间不得超过5毫秒. Garbage-First GC 会尽力达成这个目标(有很大的概率会满足, 但并不完全确定,具体是多少将是硬实时的[hard real-time])。

为了达成这项指标, G1 有一些独特的实现。首先, 堆不再分成连续的年轻代和老年代空间。而是划分为多个(通常是2048个)可以存放对象的 小堆区(smaller heap regions)。每个小堆区都可能是 Eden区, Survivor区或者Old区. 在逻辑上, 所有的Eden区和Survivor区合起来就是年轻代, 所有的Old区拼在一起那就是老年代:
![04_11_g1011.png](/images/2019/04/14/4c74ddb0-5e76-11e9-9e00-0598c74bdc4f.png)


这样的划分使得 GC不必每次都去收集整个堆空间, 而是以增量的方式来处理: 每次只处理一部分小堆区,称为此次的回收集(collection set). 每次暂停都会收集所有年轻代的小堆区, 但可能只包含一部分老年代小堆区:
![04_12_g102.png](/images/2019/04/14/52f0dea0-5e76-11e9-9e00-0598c74bdc4f.png)

G1的另一项创新, 是在并发阶段估算每个小堆区存活对象的总数。用来构建回收集(collection set)的原则是: 垃圾最多的小堆区会被优先收集。这也是G1名称的由来: garbage-first。


### Evacuation Pause: Fully Young(转移暂停:纯年轻代模式)
在应用程序刚启动时, G1还未执行过(not-yet-executed)并发阶段, 也就没有获得任何额外的信息, 处于初始的 fully-young 模式. 在年轻代空间用满之后, 应用线程被暂停, 年轻代堆区中的存活对象被复制到存活区, 如果还没有存活区,则选择任意一部分空闲的小堆区用作存活区。


## RTSJ垃圾收集器
​       RTSJ垃圾收集器，用于Java实时编程。