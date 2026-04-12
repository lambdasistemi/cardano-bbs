import Lake
open Lake DSL

package «zk-spec» where
  leanOptions := #[⟨`autoImplicit, false⟩]

@[default_target]
lean_lib «ZkSelectiveDisclosure» where
