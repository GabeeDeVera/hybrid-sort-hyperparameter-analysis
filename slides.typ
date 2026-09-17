#import "@preview/typslides:1.3.4": *
#import "../../../lib.typ": problem, aligned_block, numbered_eq, under_construction, table_of_vals, clip_graph, plot_graph, rangef
#import "@preview/cetz:0.5.2"

// Project configuration
#show: typslides.with(
  ratio: "16-9",
  theme: "bluey",
  font: "Yu Gothic UI",
  font-size: 20pt,
  link-style: "color",
  show-progress: true,
)

// The front slide is the first slide of your presentation
#front-slide(
  title: "Runtime Analysis of Hybrid Sort",
  subtitle: [Theoretical and Empirical Considerations for Hyperparameter Tuning],
  authors: "D. Tan, H. G. De Vera, P. Francis",
  // info: [#link("https://github.com/manjavacas/typslides")],
)

// Custom outline
#table-of-contents()

// Title slides create new sections
#title-slide[
  Theoretical Framework (Runtime)
]

#slide(title: "Time Complexity Analysis", outlined: true)[
  - Hybrid sort subdivides the array into smaller blocks. For blocks of size $s$ or smaller, it uses insertion sort. For larger blocks, it uses merge sort.
  - Let $s$ be the *insertion sort threshold*, the max size of the subarray where we use insertion sort. There are $O(n / s)$ blocks that we must sort with insertion sort, and each block takes $O(s^2)$ time to sort, hence *$O(n s)$* time spent sorting small blocks.
]

#slide(title: "Time Complexity Analysis", outlined: true)[
  #align(center)[#image("hybrid-sort-visual.png", width:70%)]
  - See Appendix E for a more detailed analysis.
]

#slide(title: "Time Complexity Analysis", outlined: true)[
    - The total time complexity is thus *$O(n(s - log s) + n log n) = O(n s + n log n)$*.
    - For fixed $s$, this simplifies to $O(n log n)$.
    - Hence it seems minimizing $s - log s$ suffices.
    - Attempting to minimize $n(s - log s) + n log n$ yields $s=1$.
]

#slide(title: "Time Complexity Analysis", outlined: true)[
  - For minimizing key comparisons, this analysis matches experimental results.
  - For minimizing process runtime, this approach fails.
  - *Problem:* Big-O _hides_ relevant constant factors in the objective function.
]

#focus-slide[
  Idea: Introduce Constants
]

#slide(title: "Modeling the Runtime", outlined: true)[
    #plot_graph(
    canvas_bottom_left: (-16pt, -80pt),
    canvas_top_right: (144pt, 80pt),
    coord_bottom_left: (-1.0, -5.0),
    coord_top_right: (9.0, 5.0),
    code: (fx, fy, fxi, fyi, fp, fpi) => {
      import cetz.draw: *
      let p1 = rangef(start: 0.0, stop: 9.0, step: 0.01).map((x) => (x, calc.sqrt(x * x + 1)))

      p1 = clip_graph(pts: p1)

      line(..p1.map(fp), stroke: (paint: blue))

      let p2 = rangef(start: 0.0, stop: 9.0, step: 0.01).map((x) => (x, x))

      p2 = clip_graph(pts: p2)

      line(..p2.map(fp), stroke: (paint: red))

      line(..((7.5, -3), (8, -3)).map(fp), stroke: (paint: blue), name: "func")

      line(..((7.5, -4), (8, -4)).map(fp), stroke: (paint: red), name: "func2")


      content(("func.start", 50%, "func.end"),
        angle: "func.end",
        padding: 0.3,
        anchor: "west",
        [#text(size: 0.65em)[$f(x)$]])
      
      content(("func2.start", 50%, "func2.end"),
        angle: "func2.end",
        padding: 0.3,
        anchor: "west",
        [#text(size: 0.65em)[$g(x)$]])
    }
)

  - *Definition:* Two functions $f, g$ are asymptotically equivalent iff $lim_(n arrow infinity) f(n)/g(n) = 1$
  - *Assume:*
    - Runtime of insertion sort on $n$ elements is asymptotically equivalent to $f(n) = a n^2$ for some $a in bb(R)$.
    - Runtime of merge sort on $n$ elements is asymptotically equivalent to $g(n) = b n ln n$ for some $b in bb(R)$.
]

#slide(title :"Modeling the Runtime", outlined: true)[
  #align(center)[#box(inset: 0.5em, stroke: black)[*New Objective:* Minimize total runtime#footnote[We assume $log$ is the natural log for ease of analysis. It makes the calculus cleaner. The choice of base is irrelevant as it is absorbed within the constants $a, b$.] $ F(n, s) approx a n s + b n log n - b n log s $]]

  - Under this model, *$F$ is minimized at $s = b / a$ independent of $n$*. The derivation involves calculus (see Appendix F).
]

#slide(title: "Modeling the Runtime", outlined: true)[

    *#align(center)[#box(stroke: black, inset: 0.5em)[Optimal $s$ to minimize runtime: $ s = b / a $]]*

  - Hence, as the constant of *merge sort ($b$) increases*, the model recommends *increasing $s$* so as to spend less time in merge sort and more time in insertion sort.
  - Meanwhile, as the constant of *insertion sort ($a$) increases*, the model recommends *decreasing $s$* to reduce time spent in insertion sort.
  - Model passes sanity check. ✅
  - How to find $a, b$? *Regression.*
]

#title-slide[
  Theoretical Framework (Key Comparisons)
]

#slide(title: [Worst-Case Key Comparisons], outlined: true)[
  - Let $T(n, s)$ be the *worst-case number of key comparisons* produced by Hybrid Sort over all arrays of size $n$, assuming an *insertion sort threshold* of $s$.
  - We have the following *exact recurrence* for $T(n, s)$:

  $ T(n, s) = cases(n - 1 + T(floor(n / 2), s) + T(ceil(n / 2), s) "if" n > s, n(n - 1) / 2 "otherwise") $

  - The above is computable in $O(log_2 (n / s))$ time for fixed $n$ and $s$.
]

#slide(title: "Optimizing the Worst-Case Number of Key Comparisons", outlined: true)[
  - We have both *heuristic evidence* (Appendix A) and a *mathematical induction proof* (Appendix B) that *$s=1$, $s=2$, and $s = 3$ are the only $s$ that minimize the worst-case number of key comparisons for all $n$*.
  - In the interest of time, we will skip the proof.
]

#slide(title: "Summary of Analysis", outlined: true)[
  #table(
    align: center,
    columns: (1fr, 2fr, 2fr),
    [*Objective*], [*Theoretical Optimal $s$*], [*Machine-Dependent?*],
    [Minimize Runtime], [$s = b / a$], [Yes],
    [Minimize Worst-case Key Comparisons], [$s = 1, 2, 3$], [No]
  )
]

#title-slide[
  Algorithm Implementation
]

#slide(title: [Algorithm Implementation (`hybrid_merge(a)` Skeleton)], outlined: true)[
  ```python
s = 10
keycomp = 0
def hybrid_merge(a):
  global keycomp, s
  if(len(a) <= s):
      # Insertion Sort
  else:
      # Merge Sort
  return a
  ```
]

#slide(title: "Algorithm Implementation (Insertion Sort Branch)", outlined: true)[
  ```python
for i in range(1, len(a)):
  for j in range(i - 1, -1, -1):
      keycomp += 1
      if(a[j] > a[j + 1]):
          a[j], a[j + 1] = a[j + 1], a[j]
      else:
          break  
  ```
]

#slide(title: "Algorithm Implementation (Merge Sort Branch Initialization)", outlined: true)[
  ```python
n = len(a)
m = n >> 1
l = a[0:m]
r = a[m:n]
l = hybrid_merge(l)
r = hybrid_merge(r)
l_size = m
r_size = n - m
i = 0
j = 0
ptr = 0
  ```
]

#slide(title: "Algorithm Implementation (Merge Sort Branch, Merging)", outlined: true)[
  ```python
while(i < l_size and j < r_size):
  keycomp += 1
  if(l[i] <= r[j]):
    a[ptr] = l[i]
    i += 1
  else:
    a[ptr] = r[j]
    j += 1
  ptr += 1
  ```
]

#slide(title: "Algorithm Implementation (Merge Sort Branch, Writing Tail)", outlined: true)[
  ```python
while(i < ls):
  a[ptr] = l[i]
  i += 1
  ptr += 1
while(j < rs):
  a[ptr] = r[j]
  j += 1
  ptr += 1
  ```
]

#title-slide[
  Input Data Generation
]

#slide(title: "Input Data Generation", outlined: true)[
  ```python
from random import randint

# largest integer possible in data set
x = 10**18

def gen_random_list(n):
  return list(map(lambda _: randint(1, x), range(n)))
  ```
]

#title-slide[
  Theoretical Results
]

#slide(title: [Approximations of the Worst-Case Key Comparisons], outlined: true)[
  - By applying some approximations and recurrence unrolling (see Appendix A), we obtain the following approximation for $T(n, s)$:

  $ T(n, s) approx f_1(n, s) := n (log_2(n / s) + log_2(3) - 1) - (3 n) / (2 s) + 1 + n (s / 3 - 1 / 2)  $

  - Notice that $f_1(n, s) = Theta(n s + n log n)$, which agrees with the theoretical.

  - We also found the following---better---approximation:

  $ T(n, s) approx f_2(n, s) $
  $ := n (ceil(log_2(n/s)) - 2^(ceil(log_2(n/s)))) - 2 ceil(log_2(n/s)) + 1 + n (s / (2^(ceil(log_2(n/s)) - log_2(n/s) + 1)) - 1/2) $
]

#slide(title: [Approximations of the Worst-Case Key Comparisons], outlined: true)[
    - Meanwhile, we found the following approximate upper and lower bounds:

    $ T_("upper")(n, s) := n log_2(n/s) - n/s + 1 + n(s/2-1/2) = Theta(n s + n log n) $
    $ T_("lower")(n, s) := n (log_2(n/s) + 1) - (2 n)/s + 1 + n(s/4-1/2) = Theta(n s + n log n) $

    - Hence, we have further evidence that hybrid sort runs in $O(n s + n log n)$.
]

#slide(title: "Varying the Array Size", outlined: true)[
    #align(center)[
        #image("wckeycomp-arrsz.png", width: 50%)
    ]
    - $f_1(n, s)$ (in green) achieves $R^2 = 0.9978$ for $s = 10$ and varied $n$
    - $f_2(n, s)$ (in red) achieves $R^2 = 0.9997$ for $s = 10$ and varied $n$
]

#slide(title: "Varying the Insertion Sort Threshold", outlined: true)[
    #align(center)[#image("wckeycomp-insort.png", width: 60%)]
    - $f_1(n, s)$ (in green) achieves $R^2 = 0.8333212567988$ for $n = 10^7$ and varied $s$
    - $f_2(n, s)$ (in red) achieves $R^2 = 0.999999999995$ for $n = 10^7$ and varied $s$
]

#title-slide[
  Empirical Results
]

#slide(title: "Testing Methodology", outlined: true)[
  - Timing was done with `time.perf_counter` in Python as this timer seems to minimize variance out of the available built-in timers.
  - In randomized test cases, we performed multiple timing measurements over different inputs and averaged across them. This aims to *lessen the influence of confounding variables*.
  - We ran all tests on a single computer to eliminate runtime and environment differences.
]

#slide(title: "Varying the Array Size", outlined: true)[
    #align(center)[
      #image("avgkeycomp-arrsz.png", width: 70%)
    ]
    - We plotted the average key comparisons divided by $n$ against varying input sizes.
    - Confirms theoretical analysis that if $s$ is fixed, runtime is $O(n log n)$.
    // - The above shows *avg. number of key comparisons* for $s=10$ and varying $n$.
    // - We use a log log plot to show all data points. The slope is $1$, which means that runtime is near-linear in $n$.
    // - Specifically, if $s$ were fixed, the runtime is $O(n^(1 + epsilon))$. Notice $O(n log n) = O(n^(1+epsilon))$.
]

#slide(title: "Varying the Insertion Sort Threshold", outlined: true)[
    #align(center)[
      #image("avgkeycomp-insort.png", width: 45%)
    ]
    - The above shows *avg. number of key comparisons* for $n=10000$ and varying $s$.
    - We notice that the graph tends to plateau at certain $s$ values, then jump at certain thresholds. We found that these jumps occur when $s approx n / 2^k$ for some $k in bb(Z)$.
    - We notice that the number of key comparisons is minimized at $s=1,2,3$, consistent with our theoretical model.
]

#for i in (3, 4, 5, 6, 7) {
  slide(title: [Varying Both $n$ and $s$ to Determine Optimal $s$], outlined: true)[
    #align(center)[
      #image("opts-e" + str(i) + ".png")
    ]
  ]
}

#slide(title: [Varying Both $n$ and $s$ to Determine Optimal $s$], outlined: true)[
    #align(center)[
      #image("opt-thresh-range-vs-arrsz.png", width: 60%)
    ]
    - The optimal $s$ value (by center of mass) is $s approx 9.7 approx 10$.
]

#slide(title: [Regression Analysis to Determine Optimal $s$], outlined: true)[
    #align(center)[
      #box(inset: 0.5em, stroke: black)[
        *Runtime Model*\ 
        $F(n, s) approx a n s + b n log n - b n log s$
      ]
    ]
    - We apply *least-squares regression* on our running time data across different values of $(n, s)$ using the model $F$.
    - We obtain $a approx 1.61 dot 10^(-5)$, $b approx 1.65 dot 10^(-4)$, and $R^2 = 0.9996$, indicating a strong correlation between our model and the data.
    - Using $s = b / a$, we obtain the following as the theoretical optimal value of $s$:

    #align(center)[
      #box(inset: 0.5em, stroke: black)[
        $s_("opt") = b / a approx 10.2 approx 10$
      ]
    ]

    - Our theoretical model matches our empirical analysis!
]

#slide(title: [Comparison of Hybrid Sort With Merge Sort], outlined: true)[
    #align(center)[= Final Verdict (Performance Comparison for $n=10^7$)]
    #table(
        align: center,
        columns: (1fr, 2fr, 2fr),
        [*$s$*], [*Average Runtime (s)*], [*Average Key Comparisons*],
        [$1$\ (Normal Merge Sort)], [$26.420$], [$2.201 dot 10^8$],
        [$10$\ (Hybrid Sort)], [$24.406$], [$2.264 dot 10^8$],
    )
    - We observe a *$7.6%$ increase in performance*, with only a *$2.9%$ increase in the average number of key comparisons* when tested for $n=10^7$.
]

#focus-slide[
    Thanks for Listening!
]

#title-slide[
  Appendix A: Worst-Case Analysis of the Number of Key Comparisons
]

#slide(title: "Worst-Case Analysis of the Number of Key Comparisons")[
  - Assume *0-based indexing for this analysis*.
  - For insertion sort, the worst-case is that the array is reverse-sorted. In this case, we would have to move the $i$ th element to the very beginning, incurring $i$ swaps. In total, this gives $sum_(i = 0)^(n - 1) i = (n(n - 1)) / 2$ swaps for an array of size $n$.
]

#slide(title: "Worst-Case Analysis of the Number of Key Comparisons")[
  - For merge sort, all key comparisons occur during the merge step.
  - Let $T(n)$ be the worst-case number of comparisons for an array of size $n$.
  - Supposing we split the array into $[0, floor(n/2) - 1], [floor(n/2), n - 1]$, the worst-case is that, as we do the merge, the minimum element alternates between the left and right subarrays.
  - In this case, we need to perform $n - 1$ key comparisons.
  - This yields the recurrence $T(n) = n - 1 + T(floor(n / 2)) + T(ceil(n / 2))$, where $T$ is the worst-case number of key comparisons.
]

#slide(title: "Worst-Case Analysis of the Number of Key Comparisons")[
  - For Hybrid Sort, we may modify the recurrence as follows:
  $ T(n) = cases(n - 1 + T(floor(n / 2)) + T(ceil(n / 2)) "if" n > s, n(n - 1) / 2 "otherwise") $
  - One can compute this in $O(log n)$ time. Unfortunately, as currently formulated, we could not find a closed-form for this recurrence.
  - Hence, we settled for an approximation:
  $ T(n) approx cases(n - 1 + 2T(n / 2) "if" n > s, n(n - 1) / 2 "otherwise") $
  - Note: $T(n)$ is not monotonically increasing, so we cannot cleanly bound it above.
]

#slide(title: "Worst-Case Analysis of the Number of Key Comparisons")[
  - Let $k$ be the smallest nonnegative integer so that $n / 2^k <= s$. Hence, $2^k >= n / s arrow.l.r k >= log_2 (n / s)$
  - Thus, $k = ceil(log_2(n / s))$. We can then unroll the recurrence, giving us the approximate formula:
  $ T(n) approx n k - 2^k + 1 + (n(n - 2^k)) / 2^(k + 1) $
  - As $2^k approx 1.5 n / s$, $k approx log_2(n / s) + log_2(3) - 1$.
  - Hence, an approximation for $T(n)$ is:
  $ T(n) approx n (log_2 (n/s) + log_2(3) - 1) - (3 n) / (2 s) + 1 + n(n - (3 n)/(2 s)) / ((3n) / s) $
]

#slide(title: "Worst-Case Analysis of the Number of Key Comparisons")[
  - Simplifying:
  $ T(n) approx n (log_2 (n/s) + log_2(3) - 1) - (3 n) / (2 s) + 1 + n(s/3 - (1)/(2)) $
  - Let $f(n, s) = n (log_2 (n/s) + log_2(3) - 1) - (3 n) / (2 s) + 1 + n(s/3 - (1)/(2))$. We have:

  $ (partial f) / (partial s) (n, s) = -n / (s ln(2)) + (3n) / (2s^2) + n / 3 $

  - Notice:
  $ s^2 / 3 - s / (ln(2)) + (3) / (2) = 0 arrow.l.r -1 / (s ln(2)) + (3) / (2s^2) + 1 / 3 = 0 arrow.l.r (partial f) / (partial s) (n, s) = -n / (s ln(2)) + (3n) / (2s^2) + n / 3 = 0  $
]

#slide(title: "Worst-Case Analysis of the Number of Key Comparisons")[
  - Thus, $(partial f) / (partial s) (n, s) = 0$ iff $s approx 1.73616$ or $s approx 2.59192$. In fact, $f$ is minimized at $s approx 1.72795$. However, as $s$ must be an integer, $f$ is minimized either at $s = 1$, $s = 2$, or $s = 3$.
  - Hence, as $T(n) = f(n, s)$, we find that $T(n)$ is likely minimized at $s = 1$, $s = 2$, or $s = 3$.
  - This is heuristic evidence that the minimum number occurs at around $s = 1, 2, 3$.
  - This is consistent with our empirical results!
  - The difference between minimizing runtime and minimizing number of key comparisons is that the number of key comparisons is implementation-independent. This is why it is minimized at a fixed constant, independent of constant factors $a, b$.
]

#title-slide[
    Appendix B: Co-optimality of $s=1,2,3$
]

#slide(title: "Proof of Optimality")[
    - The heuristic argument in Appendix A, as well as the empirical results, motivates us to find an mathematical proof of optimality.
    - We employ a technique known as *strong induction* to demonstrate the co-optimality of $s=1$, $s=2$, and $s=3$ under the objective of minimizing the number of key comparisons done.
]

#slide(title: "Proof of Optimality")[
    - Let $T(n, s)$ be the worst-case number of key comparisons of hybrid sort on an array with $n$ elements and an insertion sort threshold of at most $s$ elements.
    - Recall from Appendix A that:

    $ T(n, s) = cases(n - 1 + T(floor(n / 2), s) + T(ceil(n/2), s) "if" n > s, (n(n - 1)) / 2 "if" n <= s) $

    - We wish to show, for all integers $s >= 1$ and for all $n >= 1$, that $T(n, s) <= T(n, s + 1)$.
    - Let $s$ be an arbitrary integer $>= 1$. We proceed by strong induction on $n$.
    - If $1 <= n <= s: T(n, s) = T(n, s + 1) = (n(n - 1)) / 2$, so $T(n, s) <= T(n, s + 1)$.
]

#slide(title: "Proof of Optimality")[
    - If $n = s + 1$: $T(n, s + 1) = (s(s + 1))/2$ and $T(n, s) = s + T(floor((s + 1) / 2), s) + T(ceil((s + 1) / 2), s)$.
    - We note that $f(x) = (x(x - 1)) / 2$ is nondecreasing over $x >= 0$. Hence, $x >= y >= 0 arrow f(x) >= f(y)$.
]

#slide(title: "Proof of Optimality")[
    - Case 1: $s >= 4$
    - Since $floor((s + 1) / 2) <= ceil((s + 1) / 2) <= s$ for $s >= 1$,
    $T(n, s) = s + (floor((s + 1) / 2)(floor((s + 1) / 2) -1)) / 2 + (ceil((s + 1) / 2) (ceil((s + 1) / 2) - 1)) / 2 $
    
    $<= s + (ceil((s + 1) / 2) (ceil((s + 1) / 2) - 1))$
    
    $<= s + ((s + 2) / 2)((s + 2) / 2 - 1)$
    
    $= (s / 2 + 3)(s / 2)$

    $<= (s + 1)(s / 2)$ (valid for $s >= 4$)
    
    $= (s(s + 1)) / 2$

    $= T(n, s + 1)$
    - Hence, $T(n, s) <= T(n, s + 1)$ for $n = s + 1$.
]

#slide(title: "Proof of Optimality")[
    - Case 2: $s <= 3$
    - We also have $T(2, 1) = 1 <= 1 = T(2, 2)$; and,
    - $T(3, 2) = 3 <= 3 = T(3, 3)$; and,
    - $T(4, 3) = 5 <= 6 = T(4, 4)$
    - Hence, $T(n, s) <= T(n, s + 1)$ for $n = s + 1$ and $s <= 3$.
    - As we have exhausted all cases, $T(n, s) <= T(n, s + 1)$ for all integers $s >= 1$.
]

#slide(title: "Proof of Optimality")[
    - Finally, let $n$ be an arbitrary integer $> s + 1$. Suppose $T(x, s) <= T(x, s + 1)$ for $1 <= x < n$. As $n > s + 1$, $n >= s + 2 >= 1 + 2 = 3$.  Hence, $floor(n / 2) <= ceil(n / 2) < n$.
    - Thus, 
    
    $T(n, s) = n - 1 + T(floor(n / 2), s) + T(ceil(n / 2), s)$

    $<= n - 1 + T(floor(n / 2), s + 1) + T(ceil(n / 2), s + 1)$ (by the inductive hypothesis)

    $= T(n, s + 1) $

    - Hence, $T(n, s) <= T(n, s + 1)$.

    - By the principle of strong mathematical induction, $T(n, s) <= T(n, s + 1)$ holds for all $n$ and for all $s$. $square$
]

#slide(title: "Proof of Co-optimality")[
    - We wish to show $T(n, 1) = T(n, 2) = T(n, 3)$ for all integers $n >= 1$.
    - First, we have $T(1, s) = 0$, $T(2, s) = 1$, $T(3, s) = 3$, and $T(4, s) = 5$ for $s<= 3$.
    - Hence we have proven the statement for $ n<=4$.
    - We proceed once again with strong mathematical induction.
]

#slide(title: "Proof of Co-optimality")[
    - Let $n$ be an arbitrary integer $> 4$. Suppose $T(x, 1) = T(x, 2) = T(x, 3)$ for $1 <= x < n$. As $n > 4$, $n >= 5$.
    - Hence, $floor(n / 2) <= ceil(n / 2) < n$.
    - Further, as $s <= 3$, $n > s + 1$.
    - Thus, 
    
    $T(n, 1) = n - 1 + T(floor(n / 2), 1) + T(ceil(n / 2), 1)$

    $= n - 1 + T(floor(n / 2), 2) + T(ceil(n / 2), 2)$ (by the inductive hypothesis)

    $= T(n, 2) $

    $= n - 1 + T(floor(n / 2), 2) + T(ceil(n / 2), 2)$

    $= n - 1 + T(floor(n / 2), 3) + T(ceil(n / 2), 3)$ (by the inductive hypothesis)

    $= T(n, 3) $

    - Hence, $T(n, 1) = T(n, 2) = T(n, 3)$.

    - By the principle of strong mathematical induction, $T(n, 1) = T(n, 2) = T(n, 3)$ holds for all $n$. $square$

    - Hence, indeed, $s = 1$, $s = 2$, and $s = 3$ all attain the optimal worst-case number of comparisons.

    - Further, as $T(4, 3) = 5 < 6 = T(4, 4) <= T(4, s)$ for $s >= 4$, $T(4, 3) < T(4, s)$ for $s >= 4$.
    - Hence, none of $s >= 4$ could be optimal.
    - Hence, $s=1,2,3$ are the only $s$ that achieve optimality. $qed$
]

#title-slide[
  Appendix C: Computing $R^2$
]

#slide(title: [Computing $R^2$])[
    - Where applicable, we compute the coefficient of determination, $R^2$,  of a model (approximation) $Y_("pred")$ with respect to ground truth (the actual data) $Y$ as:
    
    $ R^2 := 1 - (S S_"resid") / (S S_"tot") = 1 - (EE [(Y - Y_"pred")^2]) / ("Var"(Y))  $

    - The statistic $R^2 = a$ could be interpreted as "$Y_"pred"$ explains $(100a) %$ of the variance in $Y$".
    - The closer $R^2$ is to $1$, the better the fit.
]

#title-slide[
  Appendix D: Computing Optimal $s$ Using Centre of Mass
]

#slide(title: [Computing Optimal $s$ Using Centre of Mass])[
  - Let $f(n, s)$ be the computed average runtime among randomly shuffled arrays of size $n$, with insertion sort threshold $s$.
  - Let $T in bb(R)^+$ be the closeness acceptance threshold---which we set to $T=0.01$.
  - Let $"Opt"(n) := {lr(abs(f(n, s) - min_(s^* in bb(N)) f(n, s^*)) / (min_(s^* in bb(N)) f(n, s^*)) <= T|) s in bb(N)}$.
  - We test the algorithm over $n in N_("tests")$, where $N_("tests") := {10^3, 10^4, 10^5, 10^6, 10^7}$.
  - Finally, we compute the centre of mass as:

  $ overline(s) = (sum_(n in N_("tests")) (([max "Opt"(n)][1 + max "Opt"(n)]) / 2 - ([min "Opt"(n)][-1 + min "Opt"(n)]) / 2)) / (sum_(n in N_("tests")) ([max "Opt"(n)] - [min "Opt"(n)] + 1)) $
]

#title-slide[
    Appendix E: Detailed Time Complexity Analysis of Hybrid Sort
]

#slide(title: [Detailed Time Complexity Analysis of Hybrid Sort])[
  - To sort large blocks, we need to sort blocks whose sizes are in the interval $(s, n]$. This is exactly the work needed to sort the blocks whose sizes are in the interval $[1, n]$, minus the work needed to sort blocks of size $[1, s]$. Hence, *$O(n log n - n log s)$* time spent sorting large blocks.
]

#title-slide[
    Appendix F: Modeling the Runtime
]

#slide(title :"Modeling the Runtime")[
  - *Model Limitation:* Assumes fixed constants $a, b$. Variance in runtime may occur due to hardware differences and specific implementation details. 
  - *Justification:* Since we run merge sort for large enough $n$ and insertion sort on multiple instances, variations from the asymptotic behavior should tend to disappear.
  #align(center)[#box(inset: 0.5em, stroke: black)[*New Objective:* Minimize total runtime $ F(n, s) approx a n s + b n log n - b n log s $]]
]

#slide(title: "Modeling the Runtime")[
  - *Insight:* $F(n, s) approx a n s + b n log n - b n log s = b n log n + n bold((a s - b log s))$
    - Hence equivalent to minimizing $a s - b log s$.
  - Let $f(s) = a s - b log s$. Thus, $f'(s) = a - b / s$, which is zero when $s = b / a$.#footnote[We assume $log$ is the natural log for ease of analysis. It makes the calculus cleaner. The choice of base is irrelevant as it is absorbed within the constants $a, b$.]
  - Hence, $f$ is minimized at $s = b / a$.
  - Hence, under this model, *$F$ is also minimized at $s = b / a$ independent of $n$*.
]

// // A simple slide
// #slide[
//   - This is a simple `slide` with no title.
//   - #stress("Bold and coloured") text by using `#stress(text)`.
//   - Sample link: #link("typst.app").
//     - Link styling using `link-style`: `"color"`, `"underline"`, `"both"`
//   - Font selection using `font: "Fira Sans"`, `size: 21pt`.

//   #framed[This text has been written using `#framed(text)`. The background color of the box is customisable.]

//   #framed(title: "Frame with title")[This text has been written using `#framed(title:"Frame with title")[text]`.]
// ]

// // Focus slide
// #focus-slide[
//   This is an auto-resized _focus slide_.
// ]

// // Blank slide
// #blank-slide[
//   - This is a `#blank-slide`.

//   - Available #stress[themes]#footnote[Use them as *color* functions! e.g., `#reddy("your text")`]:

//   #framed(back-color: white)[
//     #bluey("bluey"), #reddy("reddy"), #greeny("greeny"), #yelly("yelly"), #purply("purply"), #dusky("dusky"), darky.
//   ]

//   // #show: typslides.with(
//   //   ratio: "16-9",
//   //   theme: "bluey",
//   //   ...
//   // )
  

//   - Or just use *your own theme color*:
//     - `theme: rgb("30500B")`
// ]

// // Slide with title
// #slide(title: "Outlined slide", outlined: true)[
//   - Check out the *progress bar* at the bottom of the slide.

//     #h(1cm) `show-progress: true`

//   - Outline slides with `outlined: true`.

//   #grayed([This is a `#grayed` text. Useful for equations.])
//   #grayed($ P_t = alpha - 1 / (sqrt(x) + f(y)) $)

// ]

// // Columns
// #slide(title: "Columns")[

//   #cols(columns: (2fr, 1fr, 2fr), gutter: 2em)[
//     #grayed[Columns can be included using `#cols[...][...]`]
//   ][
//     #grayed[And this is]
//   ][
//     #grayed[an example.]
//   ]

//   - Custom spacing: `#cols(columns: (2fr, 1fr, 2fr), gutter: 2em)[...]`

//   // - Sample references: @typst, @typslides.
//   //   - Add a #stress[bibliography slide]...

//   //   1. `#let bib = bibliography("you_bibliography_file.bib")`
//   //   2. `#bibliography-slide(bib)`
// ]

// Bibliography
// #let bib = bibliography("bibliography.bib")
// #bibliography-slide(bib)
