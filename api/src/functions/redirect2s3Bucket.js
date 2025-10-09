const { app } = require("@azure/functions");

const s3BucketBase = "https://zhw-b.s3.cloud.switch.ch/aiub";

app.http("redirect2s3bucket", {
  methods: ["GET"],
  authLevel: "anonymous",
  handler: async (request, context) => {
    const originalUrl = request.headers["x-ms-original-url"];

    if (originalUrl) {
      // This URL has been proxied as there was no static file matching it.
      context.log(`x-ms-original-url: ${originalUrl}`);

      const url = new URL(originalUrl);
      const path = url.pathname;

      if (path === "/" || path === "") {
        // no path provided, redirect to index
        destinationUrl = "/";
      } else {
        destinationUrl = s3BucketBase + path;
      }

      context.log(`Redirecting ${originalUrl} to ${destinationUrl}`);

      context.res = {
        status: 302,
        headers: { location: destinationUrl },
      };
      return;
    }

    // No x-ms-original-url header has been set, redirect to index
    context.res = {
      status: 302,
      headers: {
        location: "/",
      },
    };
  },
});
