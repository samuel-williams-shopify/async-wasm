(module
  ;; Import memory from the host
  (memory (export "memory") 1)
  
  ;; Simple addition function
  (func $add (export "add") (param $a i32) (param $b i32) (result i32)
    local.get $a
    local.get $b
    i32.add
  )
  
  ;; Simple multiplication function
  (func $multiply (export "multiply") (param $a i32) (param $b i32) (result i32)
    local.get $a
    local.get $b
    i32.mul
  )
  
  ;; Square function
  (func $square (export "square") (param $x i32) (result i32)
    local.get $x
    local.get $x
    i32.mul
  )
  
  ;; Factorial function (iterative)
  (func $factorial (export "factorial") (param $n i32) (result i32)
    (local $result i32)
    (local $i i32)
    
    i32.const 1
    local.set $result
    
    i32.const 1
    local.set $i
    
    (block $exit
      (loop $loop
        local.get $i
        local.get $n
        i32.gt_s
        br_if $exit
        
        local.get $result
        local.get $i
        i32.mul
        local.set $result
        
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        
        br $loop
      )
    )
    
    local.get $result
  )
  
  ;; Power function (x^y)
  (func $power (export "power") (param $base i32) (param $exp i32) (result i32)
    (local $result i32)
    (local $i i32)
    
    i32.const 1
    local.set $result
    
    i32.const 0
    local.set $i
    
    (block $exit
      (loop $loop
        local.get $i
        local.get $exp
        i32.ge_s
        br_if $exit
        
        local.get $result
        local.get $base
        i32.mul
        local.set $result
        
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        
        br $loop
      )
    )
    
    local.get $result
  )
  
  ;; Maximum of two numbers
  (func $max (export "max") (param $a i32) (param $b i32) (result i32)
    local.get $a
    local.get $b
    local.get $a
    local.get $b
    i32.gt_s
    select
  )
  
  ;; Minimum of two numbers
  (func $min (export "min") (param $a i32) (param $b i32) (result i32)
    local.get $a
    local.get $b
    local.get $a
    local.get $b
    i32.lt_s
    select
  )
  
  ;; Fibonacci function (iterative)
  (func $fibonacci (export "fibonacci") (param $n i32) (result i32)
    (local $a i32)
    (local $b i32)
    (local $temp i32)
    (local $i i32)
    
    local.get $n
    i32.const 0
    i32.eq
    if (result i32)
      i32.const 0
    else
      local.get $n
      i32.const 1
      i32.eq
      if (result i32)
        i32.const 1
      else
        i32.const 0
        local.set $a
        
        i32.const 1
        local.set $b
        
        i32.const 2
        local.set $i
        
        (block $exit
          (loop $loop
            local.get $i
            local.get $n
            i32.gt_s
            br_if $exit
            
            local.get $a
            local.get $b
            i32.add
            local.set $temp
            
            local.get $b
            local.set $a
            
            local.get $temp
            local.set $b
            
            local.get $i
            i32.const 1
            i32.add
            local.set $i
            
            br $loop
          )
        )
        
        local.get $b
      end
    end
  )
  
  ;; Check if number is even
  (func $is_even (export "is_even") (param $n i32) (result i32)
    local.get $n
    i32.const 2
    i32.rem_s
    i32.const 0
    i32.eq
  )
  
  ;; Simple greeting function that returns a constant
  (func $greet (export "greet") (result i32)
    i32.const 42  ;; Return the answer to everything
  )
) 