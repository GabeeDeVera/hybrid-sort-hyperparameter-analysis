#import "@preview/typslides:1.3.4": *
#import "lib.typ": (
  aligned_block, clip_graph, numbered_eq, plot_graph, problem, rangef, table_of_vals, under_construction,
)
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
  subtitle: [Gradient Descent Methodology],
  authors: "D. Tan, H. G. De Vera, P. Francis",
  // info: [#link("https://github.com/manjavacas/typslides")],
)

// Custom outline
// #table-of-contents()

#title-slide[
  Gradient Descent Methodology
]

#slide(title: "Regression Methodology")[
  #align(center)[
    #box(inset: 0.5em, stroke: black)[
      *Runtime Model*\
      $F(n, s, theta) approx a n s + b n log n - b n log s$, where $theta = vec(delim: "[", a, b)$
    ]
  ]
  - We wish to fit the model above to our data on runtime.
  - Our runtime data $y$ consists of $(n, s, t_"time")$ tuples.
]

#slide(title: "Regression Methodology")[
  #align(center)[
    #box(inset: 0.5em, stroke: black)[
      *Goal: Minimize Squared Loss*\
      $C(y, theta) = 1 / abs(y) sum_(i = 1)^(abs(y)) [t_("time", i) - F(n_i, s_i, theta)]^2$
    ]
  ]
  - We model this regression problem as a squared-loss minimization problem. Given fixed $y$, we wish to find the value of $theta$ that minimizes $C(y, theta)$.
  - We use the *Tensorflow* library to perform *gradient descent* along parameter space.
]

#slide(title: "Parameter Initialization")[
  #align(center)[
    #box(inset: 0.5em, stroke: black)[
      *Ideal Initialization Property: Vector has Expected Norm $1$*\
      $EE [abs(theta)] = 1$
    ]
  ]
  - We initialize all weights with the same normal distribution with mean $0$---$cal(N)(0, sigma^2)$.
  - Let $X ~ cal(N)(0, sigma^2)$. Then, notice that:
  $ EE[X^2] = "Var"(X) + EE[X]^2 = sigma^2 + 0^2 = sigma^2 $
  - Hence, we have:
  $ abs(EE[theta]) = EE[sqrt(abs(theta)X^2)] = sqrt(abs(theta)EE [X^2]) = sigma sqrt(abs(theta)) = 1 $
  #align(center)[
    #box(inset: 0.5em, stroke: black)[
      $ sigma = 1 / sqrt(abs(theta)) = 1 / sqrt(2) $
    ]
  ]
]

#slide(title: "Initial Issue: Exploding Gradients")[
  - Directly running gradient descent on our original model leads to *exploding gradients*. This is most likely caused by an unconstrained output space.
  - Hence, taking inspiration from Artificial Neural Networks, we introduced an *activation function* $sigma$:

  #align(center)[
    #box(inset: 0.5em, stroke: black)[
      $ sigma(x) := (10 sqrt(10) root(3, x)) / (1 + 10 sqrt(10) abs(root(3, x))) $
    ]
  ]

  - Intuitively, $sigma$ clamps unconstrained real inputs to $[-1, 1]$. This mitigates large output values, which may lead to exploding gradients during backpropagation.
  - We also applied *gradient clipping* to prevent uncontrolled explosions.
]

#slide(title: "Smoothening the Cost Surface")[
  - With this activation function, we redefined our cost function as follows:

  #align(center)[
    #box(inset: 0.5em, stroke: black)[
      *Goal: Minimize Squared Loss*\
      $C_"norm" (y, theta) = 1 / abs(y) sum_(i = 1)^(abs(y)) [sigma(t_("time", i)) - sigma(F(n_i, s_i, theta))]^2$
    ]
  ]

  - Intuitively, this *smoothens* the cost surface, facilitating gradient descent.
  - This smoothening transformation, however, removes the resolution required to hone in on very accurate parameter values $theta$.
]

#slide(title: "Resolving the Cost Surface")[
  - *Insight:* Use $C_"norm"$ to capture the *high-level geometry* of the cost surface. Use $C$ to capture the *details* of the cost surface.
  - This insight motivates the following training procedure:
    - *Find an Approximate Soln:* Run gradient descent for $1000$ epochs with $C_"norm"$.
    - *Refine the Approximation:* Run gradient descent for $1000$ epochs with $C$.
  - *Analogy:* To find the highest point in a mountain range, first look for the correct mountain, then find the highest point on that mountain.
]

#slide(title: "Implicit Reduction of the Search Space")[
  - Another observation is that the optimal $a, b$ satisfy *$a >= 0$ and $b >= 0$*.
  - The model is *unaware* of this fact and may search regions where $a$ or $b$ are negative.
  - We believed simply clipping $a$ and $b$ to nonnegative values would be too destructive, potentially leading to gradient descent getting stuck around the boundaries of the admissible parameter space.
  - *Insight:* Define *two new parameters $a'$ and $b'$* satisfying $a'^2 = a, b'^2 = b$.
  - Hence, we *implicitly clip* the parameters by exploiting the nonnegativity of $y=x^2$.

  #align(center)[
    #box(inset: 0.5em, stroke: black)[
      *Updated Runtime Model*\
      $F(n, s, theta') approx a'^2 n s + b'^2 n log n - b'^2 n log s$, where $theta' = vec(delim: "[", a', b')$
    ]
  ]
]

#slide(title: "Summary of Algorithm")[
  #align(center)[
    #box(inset: 0.5em, stroke: black)[
      *Runtime Model*\
      $F(n, s, theta') approx a'^2 n s + b'^2 n log n - b'^2 n log s$, where $theta' = vec(delim: "[", a', b')$\
      
      *Cost Functions*\
      $C (y, theta) = 1 / abs(y) sum_(i = 1)^(abs(y)) [t_("time", i) - F(n_i, s_i, theta)]^2$\ 

      $C_"norm" (y, theta) = 1 / abs(y) sum_(i = 1)^(abs(y)) [sigma(t_("time", i)) - sigma(F(n_i, s_i, theta))]^2$
    ]
  ]
  - *Goal:* Find $theta' in bb(R)^2$ that minimizes $C(y, theta')$.
  - *The Algorithm:*
    1. Run Gradient Descent under the cost function $C_("norm") (y, theta')$, with the initial weights sampled from $cal(N)(0, 1 / sqrt(2))$.
    2. Run Gradient Descent under the cost function $C (y, theta')$, with the initial weights set to the final weight values from the first step.
]

#slide(title: "Results of Regression Analysis")[
  - This algorithm converges with $R^2 = 0.9996$.
  - An implementation of this algorithm may be found in `model_regression_analysis.py`.
  - We acknowledge the existence of exact analytical methods to minimize our objective function, which is linear-in-form.
  - We have opted to use Tensorflow as a means of exploration (and for fun)!
]