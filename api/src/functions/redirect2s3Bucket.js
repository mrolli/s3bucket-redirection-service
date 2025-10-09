const { app } = require("@azure/functions");

const s3BucketLister =
  "https://code.aiub.unibe.ch/s3_script/aiub_s3_bucket_listing.php";
const s3BucketBase = "https://zhw-b.s3.cloud.switch.ch/aiub";

/**
 * @param request
 * @param  context
 * See https://learn.microsoft.com/en-us/azure/azure-functions/functions-reference-node?tabs=javascript%2Cwindows%2Cazure-cli&pivots=nodejs-model-v4#http-triggers
 */
app.http("redirect2s3bucket", {
  methods: ["GET"],
  authLevel: "anonymous",
  handler: async (request, context) => {
    const originalUrl = request.headers["x-ms-original-url"];

    // This URL has been proxied as there was no static file matching it.
    context.log(`x-ms-original-url: ${originalUrl}`);

    // By default, if no path is found, redirect to the bucket lister
    destinationUrl = s3BucketLister;

    if (originalUrl) {
      const url = new URL(originalUrl);
      const path = url.pathname;

      if (path !== "/" && path !== "") {
        // Has path, redirect to the S3 bucket
        destinationUrl = s3BucketBase + path;
      }
    }

    context.log(`Redirecting ${originalUrl} to ${destinationUrl}`);

    return {
      status: 302,
      headers: {
        location: destinationUrl,
      },
    };
  },
});
