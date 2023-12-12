const TerserPlugin = require('terser-webpack-plugin');

module.exports = {
  optimization: {
    minimizer: [
      new TerserPlugin({
        terserOptions: {
          mangle: process.env.OPENPROJECT_ANGULAR_UGLIFY !== 'false',
          keep_classnames: true,
          keep_fnames: true,
        }
      })
    ]
  }
};
