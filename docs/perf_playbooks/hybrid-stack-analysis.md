## Hybrid stack analysis

### Preface
Stackframe analysis enables understanding what call chains ended in a given HIP API. To enable hybrid stackframe analysis, rpd must be compiled with support for this feature and the `chickensnake` submodule. Additionally, the environment variable `RPDT_STACKFRAMES=2` needs to be set when collecting the profile.

### Limitations
Stackframe analysis requires debug symbols to correctly resolve source files and line numbers. I.e., any relevant parts (the workload) should be compiled with debug symbols by setting `-g` for plain compilations, `RelWithDebInfo` as the cmake target, etc. If host libraries need to be resolved, installation of their debug packages is necessary. Without debug symbols present, only offsets into libraries/executables can be provided. E.g.,
```
in main_foo(int, char**) at /root/rocm-examples/Applications/bitonic_sort/main.hip:169:5
```
vs
```
0x00007f35a249d54b at /opt/rocm/lib/libamdhip64.so.6
```

Unlike the stackframe analysis discussed in [stackframe-analysis](stackframe-analysis.md), this feature is targeted at hybrid Python with C/C++ workloads. For purely native applications, `cpptrace` is the correct choice.

### Use with hybrid Python/C++ workloads 
After execution, the trace database will contain a `rocpd_stackframe` table:
```
sqlite> select * from rocpd_stackframe;
id|api_ptr_id|depth|name_id
1|2|0|5
2|2|1|6
3|2|2|7
4|2|3|8
5|2|4|9
6|2|5|10
7|3|0|12
8|3|1|13
9|3|2|14
10|3|3|15
11|3|4|16
12|4|0|18
13|4|1|19
14|4|2|14
15|4|3|15
16|4|4|16
17|5|0|18
18|5|1|20
19|5|2|14
20|5|3|15
```
Here, `id` is a running index, `api_ptr_id` maps to the HIP API call, `depth` is the stack depth with 0 as the highest frame (i.e., HIP API), and `name_id` maps to the frame string.

For easier readability, a temporary view can be created including the strings:
```
sqlite> create temporary view if not exists rocpd_stackstrings as select sf.id, s2.string as hip_api, s3.string as args, sf.depth, s1.string as frame from rocpd_stackframe sf join rocpd_string s1 on sf.name_id=s1.id join rocpd_api ap on sf.api_ptr_id=ap.id join rocpd_string s2 on ap.apiName_id=s2.id join rocpd_string s3 on ap.args_id=s3.id;
sqlite> select * from rocpd_stackstrings;
...
977|hipExtModuleLaunchKernel||0|	 std::unordered_map<std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >, ihipModuleSymbol_t*, std::hash<std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> > >, std::equal_to<std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> > >, std::allocator<std::pair<std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> > const, ihipModuleSymbol_t*> > >::~unordered_map (/opt/rocm-6.3.1/lib/librocblas.so.4.3.60301:0)
978|hipExtModuleLaunchKernel||1|	 Tensile::concatenate<char const (&) [6], std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> > const&> (/opt/rocm-6.3.1/lib/librocblas.so.4.3.60301:0)
979|hipExtModuleLaunchKernel||2|	 operator<< (/opt/rocm-6.3.1/lib/librocblas.so.4.3.60301:0)
980|hipExtModuleLaunchKernel||3|	 rocblas_internal_gemm<false, rocblas_complex_num<double>, rocblas_complex_num<double> const*, rocblas_complex_num<double>*> (/opt/rocm-6.3.1/lib/librocblas.so.4.3.60301:0)
981|hipExtModuleLaunchKernel||4|	 rocblas_dgemm (/opt/rocm-6.3.1/lib/librocblas.so.4.3.60301:0)
982|hipExtModuleLaunchKernel||5|	 hipblasSgemm (/opt/rocm-6.3.1/lib/libhipblas.so.2.3.60301:0)
983|hipExtModuleLaunchKernel||6|	 at::cuda::blas::gemm_internal_cublas<float> (/opt/conda/envs/py_3.10/lib/python3.10/site-packages/torch/lib/libtorch_hip.so:0)
984|hipExtModuleLaunchKernel||7|	 at::native::(anonymous namespace)::addmm_out_cuda_impl (/opt/conda/envs/py_3.10/lib/python3.10/site-packages/torch/lib/libtorch_hip.so:0)
985|hipExtModuleLaunchKernel||8|	 at::(anonymous namespace)::wrapper_CUDA_addmm (/opt/conda/envs/py_3.10/lib/python3.10/site-packages/torch/lib/libtorch_hip.so:0)
986|hipExtModuleLaunchKernel||9|	 c10::impl::wrap_kernel_functor_unboxed_<c10::impl::detail::WrapFunctionIntoFunctor_<c10::CompileTimeFunctionPointer<at::Tensor(at::Tensor const&, at::Tensor const&, at::Tensor const&, c10::Scalar const&, c10::Scalar const&), &at::(anonymous namespace)::wrapper_CUDA_addmm(at::Tensor const&, at::Tensor const&, at::Tensor const&, c10::Scalar const&, c10::Scalar const&)>, at::Tensor, c10::guts::typelist::typelist<at::Tensor const&, at::Tensor const&, at::Tensor const&, c10::Scalar const&, c10::Scalar const&> >, at::Tensor(at::Tensor const&, at::Tensor const&, at::Tensor const&, c10::Scalar const&, c10::Scalar const&)>::call (/opt/conda/envs/py_3.10/lib/python3.10/site-packages/torch/lib/libtorch_hip.so:0)
987|hipExtModuleLaunchKernel||10|	 at::_ops::addmm::redispatch (/opt/conda/envs/py_3.10/lib/python3.10/site-packages/torch/lib/libtorch_cpu.so:0)
988|hipExtModuleLaunchKernel||11|	 torch::autograd::VariableType::(anonymous namespace)::addmm (/opt/conda/envs/py_3.10/lib/python3.10/site-packages/torch/lib/libtorch_cpu.so:0)
989|hipExtModuleLaunchKernel||12|	 c10::impl::wrap_kernel_functor_unboxed_<c10::impl::detail::WrapFunctionIntoFunctor_<c10::CompileTimeFunctionPointer<at::Tensor(c10::DispatchKeySet, at::Tensor const&, at::Tensor const&, at::Tensor const&, c10::Scalar const&, c10::Scalar const&), &torch::autograd::VariableType::(anonymous namespace)::addmm(c10::DispatchKeySet, at::Tensor const&, at::Tensor const&, at::Tensor const&, c10::Scalar const&, c10::Scalar const&)>, at::Tensor, c10::guts::typelist::typelist<c10::DispatchKeySet, at::Tensor const&, at::Tensor const&, at::Tensor const&, c10::Scalar const&, c10::Scalar const&> >, at::Tensor(c10::DispatchKeySet, at::Tensor const&, at::Tensor const&, at::Tensor const&, c10::Scalar const&, c10::Scalar const&)>::call (/opt/conda/envs/py_3.10/lib/python3.10/site-packages/torch/lib/libtorch_cpu.so:0)
990|hipExtModuleLaunchKernel||13|	 at::_ops::addmm::call (/opt/conda/envs/py_3.10/lib/python3.10/site-packages/torch/lib/libtorch_cpu.so:0)
991|hipExtModuleLaunchKernel||14|	 at::native::linear (/opt/conda/envs/py_3.10/lib/python3.10/site-packages/torch/lib/libtorch_cpu.so:0)
992|hipExtModuleLaunchKernel||15|	 c10::impl::wrap_kernel_functor_unboxed_<c10::impl::detail::WrapFunctionIntoFunctor_<c10::CompileTimeFunctionPointer<at::Tensor(at::Tensor const&, at::Tensor const&, std::optional<at::Tensor> const&), &at::(anonymous namespace)::(anonymous namespace)::wrapper_CompositeImplicitAutograd__linear(at::Tensor const&, at::Tensor const&, std::optional<at::Tensor> const&)>, at::Tensor, c10::guts::typelist::typelist<at::Tensor const&, at::Tensor const&, std::optional<at::Tensor> const&> >, at::Tensor(at::Tensor const&, at::Tensor const&, std::optional<at::Tensor> const&)>::call (/opt/conda/envs/py_3.10/lib/python3.10/site-packages/torch/lib/libtorch_cpu.so:0)
993|hipExtModuleLaunchKernel||16|	 at::_ops::linear::call (/opt/conda/envs/py_3.10/lib/python3.10/site-packages/torch/lib/libtorch_cpu.so:0)
994|hipExtModuleLaunchKernel||17|	 torch::autograd::THPVariable_linear (/opt/conda/envs/py_3.10/lib/python3.10/site-packages/torch/lib/libtorch_python.so:0)
995|hipExtModuleLaunchKernel||18|	 forward (/opt/conda/envs/py_3.10/lib/python3.10/site-packages/torch/nn/modules/linear.py:117)
996|hipExtModuleLaunchKernel||19|	 _call_impl (/opt/conda/envs/py_3.10/lib/python3.10/site-packages/torch/nn/modules/module.py:1562)
997|hipExtModuleLaunchKernel||20|	 _wrapped_call_impl (/opt/conda/envs/py_3.10/lib/python3.10/site-packages/torch/nn/modules/module.py:1553)
998|hipExtModuleLaunchKernel||21|	 forward (/dockerx/simple.py:10)
999|hipExtModuleLaunchKernel||22|	 _call_impl (/opt/conda/envs/py_3.10/lib/python3.10/site-packages/torch/nn/modules/module.py:1562)
1000|hipExtModuleLaunchKernel||23|	 _wrapped_call_impl (/opt/conda/envs/py_3.10/lib/python3.10/site-packages/torch/nn/modules/module.py:1553)
1001|hipExtModuleLaunchKernel||24|	 <module> (/dockerx/simple.py:19)
1002|hipExtModuleLaunchKernel||25|	 0x7f59dc5c0d90 (/usr/lib/x86_64-linux-gnu/libc.so.6:0)
...
```
Both the Python code (not interpreter) as well as native frames (here without debug symbols compiled in) are resolved, allowing full tracking of HIP APIs through entire hybridd workloads.

### Summary
Stackframe analysis helps to identify call chains in native code to the HIP API. With debug symbols present, full resolution through for both Python and C++ parts of a hybrid workload is possible.
