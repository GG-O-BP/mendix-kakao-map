// @generated glendix — 직접 수정 금지
export default args => {
  const configs = args.configDefaultConfig;
  return configs.map(config => {
    const origExternal = config.external;
    return {
      ...config,
      external(id) {
        if (/^react(-dom)?($|\/)/.test(id)) return true;
        if (typeof origExternal === "function") return origExternal(id);
        if (Array.isArray(origExternal)) {
          return origExternal.some(e =>
            e instanceof RegExp ? e.test(id) : e === id
          );
        }
        return false;
      },
      onwarn(warning, warn) {
        if (warning.code === "CIRCULAR_DEPENDENCY") return;
        if (warning.code === "UNUSED_EXTERNAL_IMPORT") return;
        if (config.onwarn) config.onwarn(warning, warn);
        else warn(warning);
      },
    };
  });
};
