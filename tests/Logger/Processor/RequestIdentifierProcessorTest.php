<?php

declare(strict_types=1);

namespace App\Tests\Logger\Processor;

use App\Logger\Processor\RequestIdentifierProcessor;
use PHPUnit\Framework\TestCase;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\RequestStack;

final class RequestIdentifierProcessorTest extends TestCase
{
    /**
     * @dataProvider provideRequest
     *
     * @param Request|null $currentRequest
     * @param Request|null $masterRequest
     * @param string|null  $expectedRequestId
     */
    public function testProcessRecordInCLI(
        ?Request $currentRequest,
        ?Request $masterRequest,
        ?string $expectedRequestId
    ): void {
        // initialization

        /** @var RequestStack&\PHPUnit\Framework\MockObject\MockObject $requestStack */
        $requestStack = $this->createMock(RequestStack::class);
        $requestStack->expects(self::once())
                     ->method('getCurrentRequest')
                     ->willReturn($currentRequest);
        $requestStack->expects(self::once())
                     ->method('getMasterRequest')
                     ->willReturn($masterRequest);

        $object = new RequestIdentifierProcessor($requestStack);

        // execution

        $record = $object->processRecord(
            [
                'level_name' => 'INFO',
                'channel' => 'app',
                'message' => 'This is my log message',
                'datetime' => date('Y-m-d H:i:s'),
            ]
        );
        $identifier = $record['extra']['request-id'];

        $secondRecord = $object->processRecord(
            [
                'level_name' => 'ERROR',
                'channel' => 'indexing',
                'message' => 'Something went wrong while indexing an article',
                'datetime' => date('Y-m-d H:i:s'),
                'extra' => [
                    'article_id' => 42,
                    'platform' => 'fr',
                ],
            ]
        );

        // test

        $this->assertArrayHasKey('extra', $record, 'Log message should contain an "extra" section');
        $this->assertArrayHasKey(
            'request-id',
            $record['extra'],
            'Log message "extra" section should contain a "request-id" entry'
        );
        $this->assertNotNull($identifier, 'Log without request should produce a request id');
        $this->assertEquals(
            $identifier,
            $secondRecord['extra']['request-id'],
            'Two consecutive records should have the same unique identifier'
        );
        if (null !== $expectedRequestId) {
            $this->assertEquals(
                $identifier,
                $expectedRequestId,
                'Request identifier should be equal to the one specified in the request'
            );
        }
    }

    public function testProcessRecordDifferentProcessHasDifferentRequestId(): void
    {
        // initialization

        /** @var RequestStack&\PHPUnit\Framework\MockObject\MockObject $requestStack */
        $requestStack = $this->createMock(RequestStack::class);
        $requestStack->expects(self::exactly(2))
                     ->method('getCurrentRequest')
                     ->willReturn(null);
        $requestStack->expects(self::exactly(2))
                     ->method('getMasterRequest')
                     ->willReturn(null);

        $object1 = new RequestIdentifierProcessor($requestStack);
        $object2 = new RequestIdentifierProcessor($requestStack);

        $baseRecord = [
            'level_name' => 'INFO',
            'channel' => 'app',
            'message' => 'This is my log message',
            'datetime' => date('Y-m-d H:i:s'),
            'extra' => [
                'username' => 'JohnDoe',
            ],
        ];
        $record1 = $object1->processRecord($baseRecord);
        $record2 = $object2->processRecord($baseRecord);
        $identifier1 = $record1['extra']['request-id'];
        $identifier2 = $record2['extra']['request-id'];

        $this->assertNotSame($identifier1, $identifier2, 'Two records coming from two distinct request should not have the same request-id.');
        $this->assertNotSame($record1, $record2, 'The same record coming from distinct request should be different.');
    }

    public function provideRequest()
    {
        $requestWithHeader = new Request();
        $requestWithHeader->headers->set('X-Request-Id', '65f7481f-2365-4673-8312-7e9ffec4a9e1');
        $requestWithHeader2 = new Request();
        $requestWithHeader2->headers->set('X-Request-Id', '75f7481f-2365-4673-8312-7e9ffec4a9e1');

        $requestWithQueryParameter = new Request();
        $requestWithQueryParameter->query->set('request-id', '65f7481f-2365-4673-8312-7e9ffec4a9e1');

        return [
            'No request at all' => [null, null, null],
            'Request with no request id' => [new Request(), new Request(), null],
            'Current request with request id in header' => [$requestWithHeader, null, '65f7481f-2365-4673-8312-7e9ffec4a9e1'],
            'Current request with request id is better than master request' => [$requestWithHeader, $requestWithHeader2, '65f7481f-2365-4673-8312-7e9ffec4a9e1'],
            'Current request with request id in query' => [$requestWithQueryParameter, $requestWithHeader2, '65f7481f-2365-4673-8312-7e9ffec4a9e1'],
        ];
    }
}
