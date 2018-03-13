import { SES } from 'aws-sdk';
import { Context, Callback } from 'aws-lambda';

exports.handler = function(event: any, context: Context, callback: Callback) {
    console.log('Context : ' + JSON.stringify(context));

    console.log('Event : ' + JSON.stringify(event));

    // load AWS SES (as demo)
    const ses: SES = new SES({ apiVersion: '2010-12-01' });
};


