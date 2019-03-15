---
title: 分布式系统之CAP理论
date: 2017-07-23 21:30:03
tags:
  - CAP
  - 分布式
categories:
  - 架构
---

##简介

CAP 定理是分布式计算领域公认的一个定理，对于学习设计分布式系统的来说，CAP 是必须掌握的理论。

	> The CAP Theorem states that, in a distributed system (a collection of interconnected nodes that share data.), you can only have two out of the following three guarantees across a write/read pair: Consistency, Availability, and Partition Tolerance - one of them must be sacrificed

在一个分布式系统（指互相连接并共享数据的节点的集合）中，当涉及读写操作时，只能保证一致性（Consistence）、可用性（Availability）、分区容错性（Partition Tolerance）三者中的两个，另外一个必须被牺牲。

​	其中强调了两点：interconnected 和 share data，为何要强调这两点呢？ 因为**分布式系统并不一定会互联和共享数据**。最简单的例如 Memcache 的集群，相互之间就没有连接和共享数据，因此 Memcache 集群这类分布式系统就不符合 CAP 理论探讨的对象；而 MySQL 集群就是互联和进行数据复制的，因此是 CAP 理论探讨的对象。

​	**CAP 关注的是对数据的读写操作（ write/read pair），而不是分布式系统的所有功能**。例如，ZooKeeper 的选举机制就不是 CAP 探讨的对象。



##CAP

1. 一致性（Consistency）

   > A read is guaranteed to return the most recent write for a given client.
   >
   > 对某个指定的客户端来说，读操作保证能够返回最新的写操作结果。

   这里是从客户端的角度来说的，这就意味着实际上对于节点来说，可能同一时刻拥有不同数据（same time + different data），这和我们通常理解的一致性是不太一样的

   > A system has consistency if a transaction starts with the system in a consistent state, and ends with the system in a consistent state. In this model, a system can (and does) shift into an inconsistent state during a transaction, but the entire transaction gets rolled back if there is an error during any stage in the process.

   参考上述的解释，对于系统执行事务来说，**在事务执行过程中，系统其实处于一个不一致的状态，不同的节点的数据并不完全一致**，因为事务在执行过程中，client 是无法读取到未提交的数据的，只有等到事务提交后，client 才能读取到事务写入的数据，而如果事务失败则会进行回滚，client 也不会读取到事务中间写入的数据

2. 可用性（Availability）

   > A non-failing node will return a reasonable response within a reasonable amount of time (no error or timeout).
   >
   > 非故障的节点在合理的时间内返回合理的响应（不是错误和超时的响应）
   >

   只有非故障节点才能满足可用性要求，如果节点本身就故障了，发给节点的请求不一定能得到一个响应。

   不能超时、不能出错，结果是合理的，**注意没有说“正确”的结果**。例如，应该返回 100 但实际上返回了 90，肯定是不正确的结果，但可以是一个合理的结果。

3. 分区容忍性（Partition Tolerance）

   > The system will continue to function when network partitions occur.
   >
   > 当出现网络分区后，系统能够继续“履行职责”。

   

现实环境中网络本身无法做到 100% 可靠，经常可能出故障，所以分区是一个必然的现象，因此我们必须选择 P（分区容忍）要素。如果我们选择了 CA 而放弃了 P，那么当发生分区现象时，为了保证 C，系统需要禁止写入，当有写入请求时，系统返回 error（例如，当前系统不允许写入），这又和 A 冲突了，因为 A 要求返回 no error 和 no timeout。因此，分布式系统理论上不可能选择 CA 架构，只能选择 CP 或者 AP 架构。

1. CP - Consistency/Partition Tolerance

   如下图所示，为了保证一致性，当发生分区现象后，N1 节点上的数据已经更新到 y，但由于 N1 和 N2 之间的复制通道中断，数据 y 无法同步到 N2，N2 节点上的数据还是 x。这时客户端 C 访问 N2 时，N2 需要返回 Error，提示客户端 C“系统现在发生了错误”，这种处理方式违背了可用性（Availability）的要求，因此 CAP 三者只能满足 CP。

   ![Consistency/Partition Tolerance](http://robertgreiner.com/uploads/images/2014/CAP-CP-full.png)



2. AP - Availability/Partition Tolerance

   如下图所示，为了保证可用性，当发生分区现象后，N1 节点上的数据已经更新到 y，但由于 N1 和 N2 之间的复制通道中断，数据 y 无法同步到 N2，N2 节点上的数据还是 x。这时客户端 C 访问 N2 时，N2 将当前自己拥有的数据 x 返回给客户端 C 了，而实际上当前最新的数据已经是 y 了，这就不满足一致性（Consistency）的要求了，因此 CAP 三者只能满足 AP。注意：这里 N2 节点返回 x，虽然不是一个“正确”的结果，但是一个“合理”的结果，因为 x 是旧的数据，并不是一个错乱的值，只是不是最新的数据而已。

![Availability/Partition Tolerance](http://robertgreiner.com/uploads/images/2014/CAP-AP-full.png)



​	CAP 是忽略网络延迟的. 信息受到光速传播的物理定理的限制，当事务提交时，数据不能瞬间复制到所有节点。如果是相同机房，耗费时间可能是几毫秒；如果是跨地域的机房，例如北京机房同步到上海机房，耗费的时间就可能是几十毫秒。

​	这就意味着，CAP 理论中的 C 在实践中是不可能完美实现的，在数据复制的过程中，节点 A 和节点 B 的数据并不一致。

​	因此对于某些严苛的业务场景，例如和金钱相关的用户余额，技术上是无法做到分布式场景下完美的一致性的。而业务上必须要求一致性，因此单个用户的余额理论上只能选择 CA。也就是说，只能单点写入，其他节点做备份，无法做到分布式情况下多点写入。

​	这并不意味着这类系统无法应用分布式架构，只是说“单个用户余额、单个商品库存”无法做分布式，但系统整体还是可以应用分布式架构的。例如，可以对用户进行分区， 对于单个用户来说，读写操作都只能在某个节点上进行；对所有用户来说，有一部分用户的读写操作在不同的节点 上，节点之间做数据备份。这样的设计有一个很明显的问题就是某个节点故障时，这个节点上的用户就无法进行读写操作了，但站在整体上来看，这种设计可以降低节点故障时受影响的用户的数量和范围。这也是为什么挖掘机挖断光缆后，支付宝只有一部分用户会出现业务异常，而不是所有用户业务异常的原因。



- CAP 理论告诉我们分布式系统只能选择 CP 或者 AP，但其实这里的前提是系统发生了“分区”现象。如果系统没有发生分区现象，也就是说 P 不存在的时候（节点间的网络连接一切正常），我们没有必要放弃 C 或者 A，应该 C 和 A 都可以保证.
- 分区期间放弃 C 或者 A，并不意味着永远放弃 C 和 A，我们可以在分区期间进行一些操作，从而让分区故障解决后，系统能够重新达到 CA 的状态。假设我们选择了 CP，当分区恢复后，需要同步数据给之前失效的节点使系统满足 CA 的状态。假设我们选择了 AP，则分区发生后，同一数据被不同节点修改，当分区恢复后，系统按照某个规则来合并数据。也可以完全将数据冲突报告出来，由人工来选择具体应该采用哪一条。



## 数据库ACID理论

1. Atomicity（原子性）

   > 一个事务中的所有操作，要么全部完成，要么全部不完成，不会在中间某个环节结束。事务在执行过程中发生错误，会被回滚到事务开始前的状态，就像这个事务从来没有执行过一样。

2. Consistency（一致性）

   > 在事务开始之前和事务结束以后，数据库的完整性没有被破坏。 

可以看到，ACID 中的 A（Atomicity）和 CAP 中的 A（Availability）意义完全不同，而 ACID 中的 C 和 CAP 中的 C 名称虽然都是一致性，但含义也完全不一样。ACID 中的 C 是指数据库的数据完整性，而 CAP 中的 C 是指分布式节点中的数据一致性。

## BASE

BASE 是指基本可用（Basically Available）、软状态（ Soft State）、最终一致性（ Eventual Consistency），核心思想是即使无法做到强一致性（CAP 的一致性就是强一致性），但应用可以采用适合的方式达到最终一致性

1. 基本可用（Basically Available）

   > 分布式系统在出现故障时，允许损失部分可用性，即保证核心可用。 
2. 软状态（Soft State）

   > 允许系统存在中间状态，而该中间状态不会影响系统整体可用性。这里的中间状态就是 CAP 理论中的数据不一致。
3. 最终一致性（Eventual Consistency）

   > 系统中的所有数据副本经过一定时间后，最终能够达到一致的状态。

CAP理论是忽略延时的，而实际应用中延时是无法避免的,因此 CAP 中的 CP 方案，实际上也是实现了最终一致性，只不过时间很快而已。



**总结** ：ACID 是数据库事务完整性的理论，CAP 是分布式系统设计理论，BASE 是 CAP 理论中 AP 方案的延伸。



参考 ： http://robertgreiner.com/2014/08/cap-theorem-revisited/