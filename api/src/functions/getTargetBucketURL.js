const { app } = require('@azure/functions');

app.http('getTargetBucketURL', {
    methods: ['GET'],
    authLevel: 'anonymous',
    handler: async (request, context) => {
        context.log(`Http function processed request for url "${request.url}"`);

        const name = request.query.get('name') || 'the API';

        return { body: JSON.stringify({ "bucketUrl": `Hello, from ${name}!` }) };

    }
});
